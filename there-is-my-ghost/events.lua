events = {
    on_toggle = "there-is-my-ghost-toggle",
    on_toggle_bp = "there-is-my-ghost-blueprint-only",
    valid_build = { false },
    init = function()
        if not global then
            global = {}
        end
        if not global.active then
            global.active = { true }
        end
        if not global.bp_only then
            global.bp_only = { false }
        end
        if not global.cursor_stack then
            global.cursor_stack = { { last = "", current = "" } }
        end
    end,

    build_entity = function(event)
        pid = event.player_index
        if not tigm.is_active(pid) or
                not tigm.is_item_usable(game.players[pid]) then
            return
        end
        if not tigm.events.valid_build[pid] then
            game.players[pid].insert({name = event.created_entity.name, count = 1})
            event.created_entity.destroy()
            tigm.restore_stored_entities(pid)
        end

        tigm.events.valid_build[pid] = false
    end,

    put_item = function(event)
        local pid = event.player_index
        local player = game.players[pid]

        if event.shift_build then
            tigm.events.valid_build[pid] = true
            return
        end

        if not tigm.is_active(pid) then
            return
        end

        if not tigm.is_item_usable(player) then
            return
        end

        local item_dimensions = tigm.calculate_item_dimensions(player.cursor_stack.prototype.place_result.selection_box, event)

        entity_count = tigm.count_entities_in_area(item_dimensions.area, player.surface)

        if entity_count == 1 then
            ghost_name = global.cursor_stack[pid].current ~= "" and global.cursor_stack[pid].current or global.cursor_stack[pid].last
            entities = player.surface.find_entities_filtered({ area = area, name='entity-ghost', ghost_name = ghost_name })
            if tigm.is_entity_matching(entities[1], event) then
                tigm.events.valid_build[pid] = true
                return
            end
        elseif entity_count == 0 then
            if tigm.is_bp_only(pid) then
                tigm.events.valid_build[pid] = false
            else
                tigm.events.valid_build[pid] = true
            end
        end

        tigm.store_entities_in_area(item_dimensions.area, player)
    end,

    toggle = function(event)
        player = event.player_index
        if not global.active[player] then
            global.active[player] = true
        end

        global.active[player] = not global.active[player]
        tigm.events.valid_build[pid] = false
        tigm.display_message(
                {
                    text = "There is my Ghost is " .. (global.active[player] == true and "on" or "off"),
                    type = tigm.message_types.per_player
                },
                player
        )

    end,

    toggle_blueprint = function(event)
        player = event.player_index
        if not global.bp_only[player] then
            global.bp_only[player] = false
        end

        global.bp_only[player] = not global.bp_only[player]

        tigm.display_message(
                {
                    text = "There is my Ghost blueprint mode is " .. (global.bp_only[player] == true and "on" or "off"),
                    type = tigm.message_types.per_player
                },
                player
        )
    end,

    stack_change = function(event)
        pid = event.player_index
        player = game.players[pid]

        if not global.cursor_stack[pid] then
            global.cursor_stack[pid] = { last = "", current = "" }
        end
        if not player.cursor_stack.valid_for_read or
                not player.cursor_stack.prototype.place_result
        then
            current = ""
        else
            current = player.cursor_stack.prototype.place_result.name
        end

        global.cursor_stack[pid].current, global.cursor_stack[pid].last = current, global.cursor_stack[pid].current

    end
}

return events