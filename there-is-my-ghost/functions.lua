tigm = {
    message_types = {
        global = 1,
        per_player = 2
    },
    events = require "events",
    unusableItems = { "rail", "logistic-train-stop", "land-mine" },
    stored_entities = {}
}

tigm.calculate_item_dimensions = function(item_box, event)
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

    return {
        area = area,
        width = width,
        height = height,
        rectangle = rectangle
    }
end

tigm.is_entity_matching = function(entity, event)
    if not entity then
        return false
    end
    if entity.direction == event.direction and
            entity.position.x == event.position.x and
            entity.position.y == event.position.y then
        return true
    end
    return false
end

tigm.count_entities_in_area = function(area, surface)
    local count = 0
    for _, __ in pairs(surface.find_entities(area)) do
        count = count + 1
    end
    return count
end

tigm.is_item_usable = function(player)
    -- Check if the item held by the player is usable for replacing. A blueprint for example is not usable
    if player.cursor_stack.valid_for_read then
        if player.cursor_stack.prototype.place_result == nil or
                player.cursor_stack.prototype.place_as_tile_result ~= nil or
                player.cursor_stack.prototype.place_result.braking_force ~= nil or
                player.cursor_stack.prototype.place_result.speed
        then
            if not in_table(tigm.unusableItems, player.cursor_stack.name) then
                table.insert(tigm.unusableItems, player.cursor_stack.name)
            end
            return false
        elseif in_table(tigm.unusableItems, player.cursor_stack.name) then
            return false
        end
    elseif in_table(tigm.unusableItems, global.cursor_stack.last) then
        return false
    end
    return true
end

tigm.is_active = function(player)
    return global.active[player]
end

tigm.is_bp_only = function(player)
    return global.bp_only[player]
end

tigm.display_message = function(message, player)
    if player == 0 and message.type == tigm.message_types.global then
        game.print(message.text)
        return
    end

    pset = settings.get_player_settings(player)
    if pset["there-is-my-ghost-toggle-message"].value == true and message.type == tigm.message_types.per_player then
        game.players[player].print(message.text)
        return
    end
end

tigm.store_entities_in_area = function(area, player)
    for k, e in pairs(player.surface.find_entities_filtered({ area = area, name = 'entity-ghost' })) do
        tigm.store_entity(e, player.index)
    end
end

tigm.store_entity = function(entity, pid)

    local returnTable = {
        name = entity.name,
        position = entity.position,
        direction = entity.direction and entity.direction or nil,
        force = entity.force and entity.force or "player",
        inner_name = "",
        modules = "",
        request_filters = {},
        last_user = entity.last_user and entity.last_user or game.players[pid].name,
        item_requests = entity.item_requests and entity.item_requests or {},
        request_slots = { count = 0 }
    }
    if entity.ghost_type == "underground-belt" or entity.type == "underground-belt" then
        returnTable.type = entity.belt_to_ground_type
    elseif entity.ghost_type == "loader" or entity.type == "loader" then
        returnTable.type = entity.loader_type
    end

    if entity.ghost_type == "inserter" then
        returnTable.inserter_stack_size_override = entity.inserter_stack_size_override ~= nil and entity.inserter_stack_size_override or nil
    end

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

    if not tigm.stored_entities[pid] then
        tigm.stored_entities[pid] = {}
    end
    table.insert(tigm.stored_entities[pid], returnTable)
end

tigm.restore_stored_entities = function(pid)
    if not tigm.stored_entities[pid] then
        return
    end
    for k, e in pairs(tigm.stored_entities[pid]) do
        tigm.restore_stored_entity(e, game.players[pid].surface)
    end
    tigm.stored_entities[pid] = {}
end

tigm.restore_stored_entity = function(entity, surface)
    new_entity = surface.create_entity({
        name = entity.name,
        position = entity.position,
        direction = entity.direction,
        force = entity.force,
        fast_replace = false,
        recipe = entity.recipe,
        inner_name = entity.inner_name,
        type = entity.type

    })
    if new_entity.type == "inserter" then
        new_entity.inserter_stack_size_override = entity.inserter_stack_size_override ~= nil and entity.inserter_stack_size_override or nil
        for i = 0, entity.request_slots.count do
            new_entity.set_request_slot(entity.request_slots[i + 1], i + 1)
        end
    end
end