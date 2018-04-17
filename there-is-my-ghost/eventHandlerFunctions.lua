local overlapping = {false} -- if true, the next item will not be build
local usable = {true} -- if false, There is my Ghost will not try to stop the build
local previousEntities = { {} }
local cursorStack = { {last = nil, current = nil } } -- contains a history of the players cursor stack, prevents a problem when placing the last item of the stack
local active = {true} -- if false, There is my Ghost is inactive until the toggle shortcut is pressed
local bpOnly = {false} -- if true, There is my Ghost will block all placements unless the object matches the ghost, even if it is a build on a completely empty tile

-- define a table with item names that are not usable
local unusableItemNames = {"rail"}

local putItemFired = {false} -- workaround for nanobots compatibility, nanobots does fire on_build_entity, but doesn't fire on_put_item

function validatePositionedGhost(event)
    putItemFired[event.player_index] = true
    if event.shift_build == true then
        overlapping[event.player_index] = true
        return false
    end

    overlapping[event.player_index] = not bpOnly[event.player_index]

    previousEntities[event.player_index] = {}

    local player = game.players[event.player_index]
    -- Check if the item held by the player is usable in for replacing. A blueprint for example is not usable
    if player.cursor_stack == nil then
        game.print("unusable")
        usable[event.player_index] = false
        return false
    elseif heldItemIsUsable(player.cursor_stack, event.player_index) == false then
        usable[event.player_index] = false
        return false
    end
    usable[event.player_index] = true

    local position = event.position
    local surface = player.surface

    local heldItem = player.cursor_stack.name
    local heldItemResult = player.cursor_stack.prototype.place_result
    local heldItemBox = heldItemResult.selection_box

    local width = math.abs(round(heldItemBox["left_top"]["x"]) - round(heldItemBox["right_bottom"]["x"]))
    local height = math.abs(round(heldItemBox["left_top"]["y"]) - round(heldItemBox["right_bottom"]["y"]))

    -- make sure the box is at least 1x1. Yellow inserter has a box that results in a 0x0 box
    if width <= 0 then width = 1 end
    if height <= 0 then height = 1 end

    -- check if the item is a rectangle, and in the correct orientation
    local rectangle = false
    if width ~= height then
        if event.direction == defines.direction.west or event.direction == defines.direction.east then
            width, height = height, width -- flip the width and height variables. Otherwise the wrong area is scanned(north to south instead of east to west)
        end
        rectangle = true
    end

    --    local entities = {}
    local entities = surface.find_entities({ { position.x - (width / 2), position.y - (height / 2) }, { position.x + (width / 2), position.y + (height / 2) } })
    local entitiesCount = 0

    for _, e in pairs(entities) do
        if e.name == "entity-ghost" then
            entitiesCount = entitiesCount + 1
            if e.ghost_name == heldItem and isEntityAtPosition(e, position) == true then
                if (e.direction == event.direction and rectangle == true) or rectangle == false then
                    overlapping[event.player_index] = true
                else
                    overlapping[event.player_index] = false
                    storeEntity(e, event.player_index)
                end
            else
                storeEntity(e, event.player_index)
                overlapping[event.player_index] = false
            end
        elseif e.name ~= "entity-ghost" and bpOnly[event.player_index] == true then
            overlapping[event.player_index] = true
        end

        if e.name == "tile-ghost" then
            usable[event.player_index] = true
        end
    end
end

function heldItemNameIsUsable(itemname)
    if in_table(unusableItemNames, itemname) == true then return false
    else
        return true
    end
end

function heldItemIsUsable(item, index)
    if item == nil then
        item = cursorStack[index].current
    end
    if not item.valid_for_read then
--        game.print("invalid for read")
        if in_table(unusableItemNames, cursorStack[index].current) == false then
            return false
        end
    elseif item.prototype.place_result == nil then
        game.print("No place result")
        return false
    elseif in_table(unusableItemNames, item.name) == true then
--        game.print("In unusable items")
        return false
    elseif item.prototype.place_result.braking_force ~= nil then
--        game.print("Vehicle?")
        return false -- item is verhicle
    end

    return true
end

function builtOrDestroy(event)

    if putItemFired[event.player_index] == false then
        return
    end

    if active[event.player_index] == false then
        return
    end

    if usable[event.player_index] == false then
        return
    end

    local player = game.players[event.player_index]
    local itemname

    if player.cursor_stack ~= nil and player.cursor_stack.valid_for_read then
        itemname = player.cursor_stack.name
    else
        itemname = cursorStack[event.player_index].current
    end

    if overlapping[event.player_index] == false and heldItemNameIsUsable(itemname) == true then
        if event.created_entity.name == "tile-ghost" then
            overlapping[event.player_index] = not bpOnly[event.player_index]
            previousEntities[event.player_index] = {}
            return
        elseif event.created_entity.name ~= "entity-ghost" then
            player.insert({ name = itemname, count = 1 })
        end
        event.created_entity.destroy()
        if previousEntities[event.player_index] ~= nil then
            for _, e in pairs(previousEntities[event.player_index]) do
                player.surface.create_entity(entityToCreate(e))
--                Restorer:restoreControlBehavior(player.surface, e)
            end
        end
    end

    overlapping[event.player_index] = not bpOnly[event.player_index]
    previousEntities[event.player_index] = {}
    putItemFired[event.player_index] = false
end

function storeEntity(e, pi)
    local returnTable = {
        name = e.name,
        position = e.position,
        direction = e.direction and e.direction or nil,
        force = e.force and e.force or "player",
        inner_name = "",
        filters = {},
        modules = "",
        request_filters = {},
    }
    if e.ghost_type == "underground-belt" or e.type == "underground-belt" then
        returnTable.type = e.belt_to_ground_type
    elseif e.ghost_type == "loader" or e.type == "loader" then
        returnTable.type = e.loader_type
    end

    if pcall(e.get_recipe) then returnTable.recipe = e.get_recipe() and e.get_recipe().name or "" end
--    if pcall(e.get_control_behavior) and e.get_control_behavior() ~= nil then
--        returnTable.conditions = Parser:parseControlBehavior(e.get_control_behavior())
--    end

    if type(e["ghost_name"]) ~= nil then returnTable.inner_name = e.ghost_name end
    --    if type(e["filters"]) ~= nil then returnTable.filters = e.filters end
    --    if type(e["item_requests"]) ~= nil then returnTable.item_requests = e.item_requests end
    --    if type(e["request_filters"]) ~= nil then returnTable.request_filters = e.request_filters end
    table.insert(previousEntities[pi], returnTable)
end

function entityToCreate(e)
    local returnTable = {
        name = e.name,
        position = e.position,
        direction = e.direction,
        force = e.force,
        fast_replace = false,
        recipe = e.recipe,
        bar = e.bar,
        text = e.text,
        color = e.color,
        inner_name = e.inner_name,
        expires = false,
        filters = e.filters,
        modules = e.item_requests,
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

function rememberCursorStackItemName(event)
    local player = game.players[event.player_index]

    if cursorStack[event.player_index] == nil then
        cursorStack[event.player_index] = {last = nil, current = nil }
    end

    if player.cursor_stack.valid_for_read == true and player.cursor_stack ~= nil then
        if player.cursor_stack.prototype.place_result ~= nil then
            if player.cursor_stack.prototype.place_result.braking_force == true and in_table(unusableItemNames, player.cursor_stack) == false then
                table.insert(unusableItemNames, player.cursor_stack.name)
            end
        end
        cursorStack[event.player_index].last, cursorStack[event.player_index].current = cursorStack[event.player_index].current, player.cursor_stack.name
    else
        cursorStack[event.player_index].last, cursorStack[event.player_index].current = cursorStack[event.player_index].current, nil
    end
end

function toggleTIMG(event)
    active[event.player_index] = not active[event.player_index]
end

function toggleBlueprintOnly(event)
    bpOnly[event.player_index] = not bpOnly[event.player_index]
end


function playerJoined(event)
    local index = event.player_index
    if active[index] == nil then active[index] = true end
    if putItemFired[index] == nil then putItemFired[index] = false end
    if bpOnly[index] == nil then bpOnly[index] = false end
    if usable[index] == nil then cursorStack[index] = true end
    if overlapping == true or overlapping == false then
        overlapping = {false}
    elseif overlapping[index] == nil then
        overlapping[index] = false
    end

    if previousEntities[index] == nil then previousEntities[index] = {} end

    if cursorStack[index] == nil then cursorStack[index] = {last = nil, current = nil } end
end