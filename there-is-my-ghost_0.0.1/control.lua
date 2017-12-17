function round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

script.on_event(defines.events.on_put_item, function(event)
    local position = event.position
    local player = game.players[event.player_index]
    local heldItem = player.cursor_stack.name
    local surface = player.surface

    local heldItemBox = player.cursor_stack.prototype.place_result.selection_box
    local width = math.abs(round(heldItemBox["left_top"]["x"]) - round(heldItemBox["right_bottom"]["x"]))
    local height = math.abs(round(heldItemBox["left_top"]["y"]) - round(heldItemBox["right_bottom"]["y"]))

    local entities = surface.find_entities({ position, { position.x + width, position.y + height } })
    game.print("scanning "..serpent.line({ position, { position.x + width, position.y + height } }))
    for _, e in pairs(entities) do
        --        if e.name == "entity-ghost" and e.ghost_name ~= heldItem then
        --            game.print("Item doesn't equal ghost")
        --        end

        if e.name ~= "entity-ghost" then
            game.print("not ghost @"..e.position.x..","..e.position.x..": " .. e.name)
        else
            game.print("ghost @"..e.position.x..","..e.position.x..": " .. e.ghost_name)
        end

    end
end)

local function entityAtSamePosition(entity, position)
end