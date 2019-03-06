timg = {
    message_types = {
        global = 1,
        per_player = 2
    },
    events = require "events",
    unusableItems = { "rail", "logistic-train-stop", "land-mine"},
    stored_entities = {},
    debug_levels = {
        none = 0,
        log = 1,
        message = 2,
    },
    directions = {},
}
timg.debug = timg.debug_levels.none

timg.directions[0] = { defines.direction.north, defines.direction.south }
timg.directions[1] = { defines.direction.northeast, defines.direction.southwest }
timg.directions[2] = { defines.direction.east, defines.direction.west }
timg.directions[3] = { defines.direction.southeast, defines.direction.northwest }
timg.directions[4] = { defines.direction.south, defines.direction.north }
timg.directions[5] = { defines.direction.southwest, defines.direction.northeast }
timg.directions[6] = { defines.direction.west, defines.direction.east }
timg.directions[7] = { defines.direction.northwest, defines.direction.southeast }

timg.calculate_item_dimensions = function(item_box, event)
    width = math.abs(round(item_box["left_top"]["x"]) - round(item_box["right_bottom"]["x"]))
    height = math.abs(round(item_box["left_top"]["y"]) - round(item_box["right_bottom"]["y"]))

    -- make sure the box is at least 1x1. Yellow inserter has a box that results in a 0x0 box
    if width <= 0 then
        width = 1
    end
    if height <= 0 then
        height = 1
    end

    -- check if the item is a rectangle, and in the correct orientation
    rectangle = false
    if width ~= height then
        if event.direction == defines.direction.west or event.direction == defines.direction.east then
            width, height = height, width -- flip the width and height variables. Otherwise the wrong area is scanned(north to south instead of east to west)
        end
        rectangle = true
    end

    area = {
        left_top = { event.position.x - (width / 2), event.position.y - (height / 2) },
        right_bottom = { event.position.x + (width / 2), event.position.y + (height / 2) }
    }

    echo("Calculated item dimensions:")
    var_dump({
        area = area,
        width = width,
        height = height,
        rectangle = rectangle
    })

    return {
        area = area,
        width = width,
        height = height,
        rectangle = rectangle
    }
end

timg.is_entity_matching = function(entity, event)
    if entity == nil then
        echo("entity not matching, no entity")
        return false
    end

    if entity.supports_direction == true then
        if (entity.ghost_type == "underground-belt" or entity.ghost_type == "pipe-to-ground") then
            if not (timg.directions[entity.direction][1] == event.direction or timg.directions[entity.direction][2] == event.direction) then
                echo("entity direction of underground doesn't match. Events direction: " .. event.direction .. ", matching directions: " .. serpent.line(timg.directions[entity.direction]))
                return false
            end
        else
            if timg.directions[entity.direction][1] ~= event.direction then
                echo("entity direction of doesn't match. Events direction: " .. event.direction .. ", matching directions: " .. serpent.line(timg.directions[entity.direction][1]))
                return false
            end
        end
    end

    if not (entity.position.x == event.position.x and entity.position.y == event.position.y) then
        echo("pos x: " .. entity.position.x .. " == " .. event.position.x)
        echo("pos y: " .. entity.position.y .. " == " .. event.position.y)
        return false
    end

    return true
end

timg.count_entities_in_area = function(area, surface)
    local count = 0
    for _, __ in pairs(surface.find_entities_filtered({ type = "entity-ghost", area = area })) do
        count = count + 1
        echo(__.ghost_name)
    end
    --for _, __ in pairs(surface.find_entities_filtered({area=area, type="resource"})) do
    --    count = count - 1
    --end
    return count
end

timg.is_item_usable = function(player)
    -- Check if the item held by the player is usable for replacing. A blueprint for example is not usable
    if player.cursor_stack.valid_for_read then
        if player.cursor_stack.prototype.place_result == nil or
                player.cursor_stack.prototype.place_as_tile_result ~= nil or
                player.cursor_stack.prototype.place_result.braking_force ~= nil or
                player.cursor_stack.prototype.place_result.speed
        then
            if not in_table(global.unusableItems, player.cursor_stack.name) then
                table.insert(global.unusableItems, player.cursor_stack.name)
            end
            return false
        elseif in_table(global.unusableItems, player.cursor_stack.name) then
            return false
        end
    elseif in_table(global.unusableItems, global.cursor_stack.last) then
        return false
    end
    return true
end

timg.is_active = function(player)
    return global.active[player]
end

timg.is_bp_only = function(player)
    return global.bp_only[player]
end

timg.display_message = function(message, player)
    if player == 0 and message.type == timg.message_types.global then
        game.print(message.text)
        return
    end

    local pset = settings.get_player_settings(player)
    if pset["there-is-my-ghost-toggle-message"].value == true and message.type == timg.message_types.per_player then
        game.players[player].print(message.text)
        return
    end
end

timg.store_entities_in_area = function(area, player)
    for k, e in pairs(player.surface.find_entities_filtered({ area = area, name = 'entity-ghost' })) do
        timg.store_entity(e, player.index)
    end
end

timg.store_entity = function(entity, pid)

    local returnTable = {
        name = entity.name,
        position = entity.position,
        direction = entity.supports_direction == true and entity.direction or nil,
        force = entity.force and entity.force or "player",
        inner_name = "",
        modules = "",
        request_filters = {},
        last_user = entity.last_user and entity.last_user or game.players[pid].name,
        item_requests = entity.item_requests and entity.item_requests or {},
        request_slots = { count = 0 }
    }

    if returnTable.direction ~= nil and entity.supports_direction == false then
        echo("direction not supported, but stored direction set")
    end

    returnTable = timg.store_underground_belt(entity, returnTable)
    returnTable = timg.store_loader(entity, returnTable)
    returnTable = timg.store_inserter(entity, returnTable)
    returnTable = timg.store_splitter(entity, returnTable)

    if pcall(entity.get_recipe) then
        returnTable.recipe = entity.get_recipe() and entity.get_recipe().name or ""
    end
    if type(entity["ghost_name"]) ~= nil then
        returnTable.inner_name = entity.ghost_name
    end
    returnTable.request_slots.count = entity.request_slot_count
    if entity.request_slot_count ~= 0 then
        for i = 0, entity.request_slot_count do
            returnTable.request_slots[i + 1] = entity.get_request_slot(i + 1)
        end
    end

    if not timg.stored_entities[pid] then
        timg.stored_entities[pid] = {}
    end
    table.insert(timg.stored_entities[pid], returnTable)
end

timg.store_splitter = function(entity, returnTable)
    if not (entity.ghost_type == "splitter" or entity.type == "splitter") then
        return returnTable
    end
    -- Doesn't work in 0.16. Should work in 0.17
    --returnTable.splitter_filter = entity.splitter_filter ~= nil and entity.splitter_filter or nil
    --returnTable.splitter_input_priority = entity.splitter_input_priority ~= nil and entity.splitter_input_priority or nil
    --returnTable.splitter_output_priority = entity.splitter_output_priority ~= nil and entity.splitter_output_priority or nil
    return returnTable
end

timg.store_inserter = function(entity, returnTable)
    if entity == nil then
        return returnTable
    end
    if not (entity.ghost_type == "inserter" or entity.type == "inserter") then
        return returnTable
    end

    returnTable.inserter_stack_size_override = entity.inserter_stack_size_override ~= nil and entity.inserter_stack_size_override or nil
    returnTable.pickup_position = entity.pickup_position
    returnTable.drop_position = entity.drop_position

    return returnTable
end

timg.store_underground_belt = function(entity, returnTable)
    if entity == nil then
        return returnTable
    end
    if not (entity.ghost_type == "underground-belt" or entity.type == "underground-belt") then
        return returnTable
    end

    returnTable.type = entity.belt_to_ground_type

    return returnTable
end

timg.store_loader = function(entity, returnTable)
    if entity == nil then
        return returnTable
    end
    if not (entity.ghost_type == "loader" or entity.type == "loader") then
        return returnTable
    end

    returnTable.type = entity.loader_type

    return returnTable
end

timg.restore_stored_entities = function(pid)
    if not timg.stored_entities[pid] then
        return
    end
    for k, e in pairs(timg.stored_entities[pid]) do
        timg.restore_stored_entity(e, game.players[pid].surface)
    end
    timg.stored_entities[pid] = {}
end

timg.restore_stored_entity = function(entity, surface)
    new_entity = surface.create_entity(
            {
                name = entity.name,
                position = entity.position,
                direction = entity.direction,
                force = entity.force,
                fast_replace = false,
                recipe = entity.recipe,
                inner_name = entity.inner_name,
                type = entity.type
            }
    )
    new_entity = timg.restore_inserter(new_entity, entity)
    new_entity = timg.restore_splitter(new_entity, entity)

    if new_entity.request_slot_count > 0 then
        for i = 0, entity.request_slots.count do
            new_entity.set_request_slot(entity.request_slots[i + 1], i + 1)
        end
    end
    echo("Restored entity:" .. (new_entity.name == "entity-ghost" and "ghost of " .. new_entity.ghost_name or new_entity.name))
end

timg.restore_splitter = function(entity, stored_entity)
    if entity == nil then
        return entity
    end
    if not (entity.ghost_type == "splitter" or entity.type == "splitter") then
        return entity
    end
    --entity.splitter_filter = stored_entity.splitter_filter ~= nil and stored_entity.splitter_filter or nil
    --entity.splitter_input_priority = stored_entity.splitter_input_priority ~= nil and stored_entity.splitter_input_priority or nil
    --entity.splitter_output_priority = stored_entity.splitter_output_priority ~= nil and stored_entity.splitter_output_priority or nil
    return entity
end

timg.restore_inserter = function(entity, stored_entity)
    if entity == nil then
        return entity
    end
    if not (entity.ghost_type == "inserter" or entity.type == "inserter") then
        return entity
    end
    entity.inserter_stack_size_override = stored_entity.inserter_stack_size_override ~= nil and stored_entity.inserter_stack_size_override or nil
    entity.drop_position = stored_entity.drop_position ~= nil and stored_entity.drop_position or nil
    entity.pickup_position = stored_entity.pickup_position ~= nil and stored_entity.pickup_position or nil

    return entity
end

timg.generate_unusable_items_table = function()
    if not global.unusableItems then
        global.unusableItems = { "straight-rail", "rail", "logistic-train-stop", "land-mine" }
    end
end