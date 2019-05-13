events = {
    on_toggle = "there-is-my-ghost-toggle",
    on_toggle_button = "there-is-my-ghost-toggle-shortcut",
    on_toggle_bp = "there-is-my-ghost-blueprint-only",
    on_toggle_bp_button = "there-is-my-ghost-blueprint-only-shortcut",
    is_map_editor = false,
    valid_build = { false },
    reserved_inventory_spot = {0},
    init = function()

        if not global == nil then
            global = {}
        end
        if global.active == nil then
            global.active = { true }
        end
        if global.bp_only == nil then
            global.bp_only = { false }
        end
        if global.unusableItems == nil then
            timg.generate_unusable_items_table()
        end
        if global.reserved_inventory_spot == nil then
            global.reserved_inventory_spot = {0}
        end

        for i, player in pairs(game.players) do
            if player.is_shortcut_available(timg.events.on_toggle_button) then
                player.set_shortcut_toggled(timg.events.on_toggle_button, global.active[player.index])
            end
            if player.is_shortcut_available(timg.events.on_toggle_bp_button) then
                player.set_shortcut_toggled(timg.events.on_toggle_bp_button, global.bp_only[player.index])
            end
        end
    end,

    on_config_change = function()
        timg.events.init()
    end,

    map_editor_toggle = function(event)
        timg.events.is_map_editor = true
        for i, v in pairs(global.active) do
            global.active[i] = false
            global.bp_only[i] = false
        end
    end,

    build_entity = function(event)
        echo(event.created_entity.name)
        pid = event.player_index
        echo("build")
        echo(serpent.block(event))

        echo("item usable "..(timg.is_item_usable(game.players[pid]) and "true" or "false"))

        if (not timg.is_active(pid)) or (not timg.is_item_usable(game.players[pid])) then
            echo("TIMG is not active or the item is unusable. TIMG is " .. (timg.is_active(pid) and "active" or "not active"))
            return
        end

        if event.created_entity.name == "entity-ghost" then
            echo("it was an entity ghost")
            return
        end

        echo("valid_build set to: " .. (timg.events.valid_build[pid] and "true" or "false"))
        if not timg.events.valid_build[pid] then
            entityName = event.created_entity.name

            echo(entityName.." invalid build, restoring entities")
            if event.created_entity.destroy({raise_destroy = true}) then
                game.players[pid].insert({ name = event.item.name, count = 1 })
                timg.restore_stored_entities(pid)
            end
        end

        timg.events.reset_valid_build(pid)
    end,

    put_item = function(event)
        echo("put_item")
        local pid = event.player_index
        local player = game.players[pid]

        echo(serpent.block(event))

        if event.shift_build then
            echo("a valid shift build")
            timg.events.valid_build[pid] = true
            return
        end

        if not timg.is_active(pid) then
            return
        end

        if not timg.is_item_usable(player) then
            return
        end
        if player.cursor_stack.valid_for_read == false then
            echo("cursor stack invalid")
            timg.events.valid_build[pid] = false
            return
        end
        local item_dimensions = timg.calculate_item_dimensions(player.cursor_stack.prototype.place_result.selection_box, event)

        entity_count = timg.count_entities_in_area(item_dimensions.area, player.surface)
        echo("counted " .. entity_count .. " entities")
        if entity_count == 1 then
            ghost_name = timg.intermod.intermodCompat(player.cursor_stack.prototype.name)
            entities = player.surface.find_entities_filtered({ area = area, name = 'entity-ghost', ghost_name = ghost_name })
            if timg.is_entity_matching(entities[1], event) then
                echo("entities match")
                timg.events.valid_build[pid] = true
                return
            else
                echo("entities don't match")
                timg.events.valid_build[pid] = false
            end
        elseif entity_count == 0 then
            echo("no entities detected")
            if timg.is_bp_only(pid) then
                echo("bp_only invalid build")
                timg.events.valid_build[pid] = false
            else
                echo("build is valid")
                timg.events.valid_build[pid] = true
                return
            end
        else
            timg.events.valid_build[pid] = false
        end
        timg.store_entities_in_area(item_dimensions.area, player)
        echo("end put_item")
    end,

    toggle = function(event)
        if timg.events.is_map_editor == true then
            return
        end
        player = event.player_index

        if global.active == nil then
            global.active = {}
        end
        if global.active[player] == nil then
            global.active[player] = true
        end

        global.active[player] = not global.active[player]
        if game.players[player].is_shortcut_available(timg.events.on_toggle_button) then
            game.players[player].set_shortcut_toggled(timg.events.on_toggle_button, global.active[player])
        end
        timg.events.valid_build[player] = false
        --timg.display_message(
        --        {
        --            text = "There is my Ghost is " .. (global.active[player] == true and "on" or "off"),
        --            type = timg.message_types.per_player
        --        },
        --        player
        --)
    end,

    toggle_blueprint = function(event)
        if timg.events.is_map_editor == true then
            return
        end
        player = event.player_index

        if global.bp_only == nil then
            global.bp_only = {}
        end
        if global.bp_only[player] == nil then
            global.bp_only[player] = false
        end

        global.bp_only[player] = not global.bp_only[player]
        if game.players[player].is_shortcut_available(timg.events.on_toggle_bp_button) then
            game.players[player].set_shortcut_toggled(timg.events.on_toggle_bp_button, global.bp_only[player])
        end

        --timg.display_message(
        --        {
        --            text = "There is my Ghost blueprint mode is " .. (global.bp_only[player] == true and "on" or "off"),
        --            type = timg.message_types.per_player
        --        },
        --        player
        --)
    end,

    reset_valid_build = function(pid)
        if timg.is_bp_only(pid) then
            timg.events.valid_build[pid] = false
        else
            timg.events.valid_build[pid] = true
        end
    end,

    print_global = function()
        game.print(serpent.line(global))
    end,

    toggle_debug = function()
        local level = "undefined"
        if timg.debug == timg.debug_levels.message then
            timg.debug = timg.debug_levels.none
            level = "no"
        elseif timg.debug == timg.debug_levels.log then
            timg.debug = timg.debug_levels.message
            level = "message"
        elseif timg.debug == timg.debug_levels.none then
            timg.debug = timg.debug_levels.log
            level = "log"
        end
        game.print("There is my ghost is now in" .. level .. " debug mode")
    end,

    shortcut = function(event)
        if event.prototype_name == timg.events.on_toggle_button then
            timg.events.toggle(event)
        elseif event.prototype_name == timg.events.on_toggle_bp_button then
            timg.events.toggle_blueprint(event)
        end
    end
}

return events