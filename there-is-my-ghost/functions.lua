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
timg.debug = timg.debug_levels.message


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

function timg.calculate_item_dimensions(item_box, direction, position)
    echo("timg.calculate_item_dimensions: begin")
    local width = math.abs(round(item_box["left_top"]["x"]) - round(item_box["right_bottom"]["x"]))
    local height = math.abs(round(item_box["left_top"]["y"]) - round(item_box["right_bottom"]["y"]))
    echo("timg.calculate_item_dimensions: width="..width..", height="..height)
    -- make sure the box is at least 1x1. Yellow inserter has a box that results in a 0x0 box
    if width <= 0 then
        width = 1
    end
    if height <= 0 then
        height = 1
    end

    -- check if the item is a rectangle, and in the correct orientation
    local rectangle = false
    if width ~= height then
        if direction == defines.direction.west or direction == defines.direction.east then
            width, height = height, width -- flip the width and height variables. Otherwise the wrong area is scanned(north to south instead of east to west)
        end
        rectangle = true
    end

    local area = {
        left_top = { position.x - (width / 2), position.y - (height / 2) },
        right_bottom = { position.x + (width / 2), position.y + (height / 2) }
    }
    echo("timg.calculate_item_dimensions: end")
    return {
        area = area,
        width = width,
        height = height,
        rectangle = rectangle
    }
end

function timg.is_entity_matching(entity, event)
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

    return (entity.position.x == event.position.x and entity.position.y == event.position.y)
end

function timg.count_entities_in_area(area, surface)
    local count = 0
    for _, __ in pairs(surface.find_entities_filtered({ type = "entity-ghost", area = area })) do
        count = count + 1
    end
    return count
end

function timg.check_ghost(prototype_name, event, area)
    local ghost_name = timg.intermod.intermodCompat(prototype_name)
    echo("check_ghost: ghost name "..ghost_name)
    var_dump(area)
    local entities = game.get_player(event.player_index).surface.find_entities_filtered({ area = area, name = 'entity-ghost', ghost_name = ghost_name})
    echo("check_ghost: ghosts found ".. count(entities))
    return timg.is_entity_matching(entities[1], event)
end

function timg.is_item_usable(stack)
    return stack.place_result.fast_replaceable_group ~= nil and not in_table(timg.unusableItems.fast_replace, stack.place_result.fast_replaceable_group)
end

function timg.is_active(player)
    return game.players[player].is_shortcut_toggled(timg.events.on_toggle_button)
end

function timg.is_bp_only(player)
    echo(player)
    return game.players[player].is_shortcut_toggled(timg.events.on_toggle_bp_button)
end

function timg.display_message(message, player)
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

function timg.store_entities_in_area(area, pid)
    local player = game.get_player(pid)
    local entities = player.surface.find_entities_filtered({ area = area, name = 'entity-ghost' })
    echo("timg.store_entities_in_area: storing "..count(entities).." entities")
    for k, e in pairs(entities) do
        timg.store_entity(e, pid)
    end
end

function timg.store_entity(entity, pid)
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
    var_dump(returnTable)
    table.insert(timg.stored_entities[pid], returnTable)
    echo("store_entity: end")
end

function timg.store_splitter(entity, returnTable)
    if not (entity.ghost_type == "splitter" or entity.type == "splitter") then
        return returnTable
    end

    returnTable.splitter_filter = entity.splitter_filter ~= nil and entity.splitter_filter.name or nil
    returnTable.splitter_input_priority = entity.splitter_input_priority ~= nil and entity.splitter_input_priority or nil
    returnTable.splitter_output_priority = entity.splitter_output_priority ~= nil and entity.splitter_output_priority or nil
    return returnTable
end

function timg.store_inserter(entity, returnTable)
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

function timg.store_underground_belt(entity, returnTable)
    if entity == nil then
        return returnTable
    end
    if not (entity.ghost_type == "underground-belt" or entity.type == "underground-belt") then
        return returnTable
    end

    returnTable.type = entity.belt_to_ground_type

    return returnTable
end

function timg.store_loader(entity, returnTable)
    if entity == nil then
        return returnTable
    end
    if not (entity.ghost_type == "loader" or entity.type == "loader") then
        return returnTable
    end

    returnTable.type = entity.loader_type

    return returnTable
end

function timg.restore_stored_entities(pid)

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

function timg.restore_stored_entity(stored_entity, surface, event)
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

function timg.restore_splitter(entity, stored_entity)
    if entity == nil then
        return entity
    end
    if not (entity.ghost_type == "splitter" or entity.type == "splitter") then
        return entity
    end
    entity.splitter_filter = stored_entity.splitter_filter ~= nil and stored_entity.splitter_filter or nil
    entity.splitter_input_priority = stored_entity.splitter_input_priority ~= nil and stored_entity.splitter_input_priority or nil
    entity.splitter_output_priority = stored_entity.splitter_output_priority ~= nil and stored_entity.splitter_output_priority or nil
    return entity
end

function timg.restore_inserter(entity, stored_entity)
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

function timg.generate_unusable_items_table()
    if not global.unusableItems then
        global.unusableItems = {
            items = {},
            types = {},
            fast_replace = {}
        }
    end
end