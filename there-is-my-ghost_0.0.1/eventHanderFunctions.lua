

function validatePositionedGhost(event)
    --    game.print("on_put_item")
    local position = event.position
    local player = game.players[event.player_index]
    local heldItem = player.cursor_stack.name
    local surface = player.surface

    local heldItemBox = player.cursor_stack.prototype.place_result.selection_box
    local width = math.abs(round(heldItemBox["left_top"]["x"]) - round(heldItemBox["right_bottom"]["x"]))
    local height = math.abs(round(heldItemBox["left_top"]["y"]) - round(heldItemBox["right_bottom"]["y"]))

    local entities = surface.find_entities({ { position.x - (width / 2), position.y - (height / 2) }, { position.x + (width / 2), position.y + (height / 2) } })
    --    game.print("scanning " .. serpent.line({ { position.x - (width / 2), position.y - (height / 2) }, { position.x + (width / 2), position.y + (height / 2) } }))
    local entitiesCount = 0
    for _, e in pairs(entities) do
        entitiesCount = entitiesCount + 1
        if e.name == "entity-ghost" then
            if e.ghost_name == heldItem and isEntityAtPosition(e, position) then
                overlapping = true
            else
                storeEntity(e)
            end
        end
    end
    if entitiesCount == 0 then overlapping = true end
end

function buildOrDestroy (event)
    --    game.print("on_build_entity")
    --    game.print(event.created_entity.name)
    local player = game.players[event.player_index]
    if overlapping == false then
        player.insert({name = event.created_entity.name, count=1})
        event.created_entity.destroy()
        for _, e in pairs(previousEntities) do
            player.surface.create_entity(entityToCreate(e))
        end
    end
    overlapping = false
    previousEntities = {}
end

function storeEntity(e)
    local returnTable = {
        name = e.name,
        position = e.position,
        direction = e.direction and e.direction or nil,
        force = e.force and e.force or "player",
        inner_name = "",
        filters = {},
        modules = "",
        request_filters =  {}
    }
    if e.ghost_type == "underground-belt" or e.type == "underground-belt" then
        returnTable.type = e.belt_to_ground_type
    elseif e.ghost_type == "loader" or e.type == "loader" then
        returnTable.type = e.loader_type
    end

    if e.prototype.subgroup == "production-machine" then
        returnTable.recipe = e.get_recipe() and e.get_recipe() or ""
    end

    if type(e["ghost_name"]) ~= nil then returnTable.inner_name = e.ghost_name end
    --    if type(e["conditions"]) ~= nil then returnTable.conditions = e.conditions end
    --    if type(e["filters"]) ~= nil then returnTable.filters = e.filters end
    --    if type(e["item_requests"]) ~= nil then returnTable.item_requests = e.item_requests end
    --    if type(e["request_filters"]) ~= nil then returnTable.request_filters = e.request_filters end
    --    game.print(returnTable.inner_name)
    table.insert(previousEntities, returnTable)
end

function entityToCreate(e)
    local returnTable = {
        name = e.name,
        position = e.position,
        direction = e.direction,
        force = e.force,
        fast_replace = false,
        recipe = e.recipe,
        bar = e.bar ,
        text = e.text,
        color = e.color,
        inner_name = e.inner_name,
        expires = false,
        conditions = e.conditions ,
        filters = e.filters ,
        modules = e.item_requests ,
        request_filters = e.request_filters,
        type = e.type
    }

    return returnTable
end

function isEntityAtPosition(entity, position)
    local x = entity.position.x
    local y = entity.position.y

    if position.x == x and position.y == y then
        return true
    end
    return false
end