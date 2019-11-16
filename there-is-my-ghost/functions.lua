timg = {
    message_types = {
        global = 1,
        per_player = 2
    },
    events = require "events",

    stored_entities = {},
    debug_levels = {
        none = 0,
        log = 1,
        message = 2,
    },
    directions = {},
    intermod = require "intermod",
}
timg.debug = timg.debug_levels.log


local unusable = require "unusables"
timg.unusableItems, timg.unreturnable = unusable[1], unusable[2]

timg.directions[0] = { defines.direction.north, defines.direction.south }
timg.directions[1] = { defines.direction.northeast, defines.direction.southwest }
timg.directions[2] = { defines.direction.east, defines.direction.west }
timg.directions[3] = { defines.direction.southeast, defines.direction.northwest }
timg.directions[4] = { defines.direction.south, defines.direction.north }
timg.directions[5] = { defines.direction.southwest, defines.direction.northeast }
timg.directions[6] = { defines.direction.west, defines.direction.east }
timg.directions[7] = { defines.direction.northwest, defines.direction.southeast }

function timg.calculate_item_dimensions(item_box, event)
    echo("timg.calculate_item_dimensions: begin")
    width = math.abs(round(item_box["left_top"]["x"]) - round(item_box["right_bottom"]["x"]))
    height = math.abs(round(item_box["left_top"]["y"]) - round(item_box["right_bottom"]["y"]))
    echo("timg.calculate_item_dimensions: width="..width..", height="..height)
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
    --var_dump({
    --    area = area,
    --    width = width,
    --    height = height,
    --    rectangle = rectangle
    --})
    echo("timg.calculate_item_dimensions: end")
    return {
        area = area,
        width = width,
        height = height,
        rectangle = rectangle
    }
end

timg.is_entity_matching = function(entity, event)
    if entity == nil then
        echo("is_entity_matching: entity doesn't match with placed entity, no entity")
        return false
    end

    if entity.supports_direction == true then
        if (entity.ghost_type == "underground-belt" or entity.ghost_type == "pipe-to-ground") then
            if not (timg.directions[entity.direction][1] == event.direction or timg.directions[entity.direction][2] == event.direction) then
                return false
            end
        else
            if timg.directions[entity.direction][1] ~= event.direction then
                return false
            end
        end
    end

    if not (entity.position.x == event.position.x and entity.position.y == event.position.y) then
        return false
    end

    return true
end

timg.count_entities_in_area = function(area, surface)
    local count = 0
    for _, __ in pairs(surface.find_entities_filtered({ type = "entity-ghost", area = area })) do
        count = count + 1
    end
    return count
end

timg.is_item_name_or_type_usable = function(name, type, fast_replace)
    if name ~= nil and in_table(global.unusableItems.items, name) or in_table(timg.unusableItems.items, name) then
        echo(name)
        return false
    end
    if type ~= nil and in_table(global.unusableItems.type, type) or in_table(timg.unusableItems.type, type) then
        echo(type)
        return false
    end
    if fast_replace ~= nil and in_table(global.unusableItems.fast_replace, fast_replace) or in_table(timg.unusableItems.fast_replace, fast_replace) then
        echo(fast_replace)
        return false
    end
    return true
end

timg.is_item_usable = function(stack)
    -- Check if the item held by the player is usable for replacing. A blueprint for example is not usable
    if stack ~= nil and stack.valid_for_read then
        if stack.prototype.place_result == nil or
                stack.prototype.place_as_tile_result ~= nil or
                stack.prototype.place_result.braking_force ~= nil or
                stack.prototype.place_result.speed
        then
            if timg.is_item_name_or_type_usable(stack.name) then
                table.insert(global.unusableItems.items, stack.name)
            end
            return false
        elseif timg.is_item_name_or_type_usable(stack.name, stack.type, stack.prototype.place_result.fast_replaceable_group) then
            echo("is_item_usable: Item is usable")
            return true
        end
        echo("is_item_usable: not item_name_or_type_usable")
        return false
    end
    echo("is_item_usable: stack is valid for read")
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
    local entities = player.surface.find_entities_filtered({ area = area, name = 'entity-ghost' })
    echo("timg.store_entities_in_area: storing "..count(entities).." entities")
    for k, e in pairs(entities) do
        timg.store_entity(e, player.index)
    end
end

timg.store_entity = function(entity, pid)
    echo("store_entity: called for "..entity.name)
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
        echo("store_entity: direction not supported, but stored direction set")
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
    echo("store_entity: returntable is")
    --var_dump(returnTable)
    table.insert(timg.stored_entities[pid], returnTable)
    echo("store_entity: end")
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

    echo("restore_stored_entities: begin")
    if not timg.stored_entities[pid] then
        echo("restore_stored_entities: no stored entities, ending here")
        return
    end
    echo("restore_stored_entities: restoring "..count(timg.stored_entities[pid]).." entities")
    local count=0
    for k, e in pairs(timg.stored_entities[pid]) do
        count = count+1
        timg.restore_stored_entity(e, game.players[pid].surface, event)
    end

    timg.stored_entities[pid] = {}
    echo("restore_stored_entities: end with a count of "..count)
end

timg.restore_stored_entity = function(stored_entity, surface, event)
    echo("restore_stored_entity: begin")
    local new_entity = surface.create_entity(
            {
                name = stored_entity.name,
                position = stored_entity.position,
                direction = stored_entity.direction,
                force = stored_entity.force,
                fast_replace = false,
                recipe = stored_entity.recipe,
                inner_name = stored_entity.inner_name,
                type = stored_entity.type
            }
    )
    if new_entity == nil then
        echo("restore_stored_entity: placed entity is nil")
        return false
    end

    new_entity = timg.restore_inserter(new_entity, stored_entity)
    new_entity = timg.restore_splitter(new_entity, stored_entity)

    if new_entity.request_slot_count > 0 then
        for i = 0, stored_entity.request_slots.count do
            new_entity.set_request_slot(stored_entity.request_slots[i + 1], i + 1)
        end
    end
    echo("restore_stored_entity: Restored entity:" .. (new_entity.name == "entity-ghost" and "ghost of " .. new_entity.ghost_name or new_entity.name))
    echo("restore_stored_entity: end")
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
        global.unusableItems = {
            items = {},
            types = {},
            fast_replace = {}
        }
    end
end