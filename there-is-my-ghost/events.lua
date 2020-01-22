events = {
    on_toggle = "there-is-my-ghost-toggle",
    on_toggle_button = "there-is-my-ghost-toggle-shortcut",
    on_toggle_bp = "there-is-my-ghost-blueprint-only",
    on_toggle_bp_button = "there-is-my-ghost-blueprint-only-shortcut",
    is_map_editor = false,
    valid_build = { false },
    reserved_inventory_spot = { 0 },
    init = function()

        if not global == nil then
            global = {}
        end
        if global.active == nil then
            global.active = { false }
        end
        if global.bp_only == nil then
            global.bp_only = { false }
        end
        if global.unusableItems == nil then
            timg.generate_unusable_items_table()
        end
        if global.reserved_inventory_spot == nil then
            global.reserved_inventory_spot = { 0 }
        end

        for i, player in pairs(game.players) do
            if player.is_shortcut_available(timg.events.on_toggle_button) then
                player.set_shortcut_toggled(timg.events.on_toggle_button, false)
            end
            if player.is_shortcut_available(timg.events.on_toggle_bp_button) then
                player.set_shortcut_toggled(timg.events.on_toggle_bp_button, false)
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

        echo("build_entity: begin")
        echo(serpent.block(event))

        if (event.item == nil) then
            echo("build_entity: event.item is nil")
            return
        elseif (not timg.is_active(event.player_index)) then
            echo("build_entity: TIMG not active")
            return
        elseif not timg.is_item_usable(event.item) then
            echo("build_entity: item not usable")
            return
        elseif (event.created_entity.name == "entity-ghost") then
            echo("build_entity: it was an entity ghost")
            return
        elseif (timg.events.valid_build[event.player_index]) then
            timg.events.reset_valid_build(event.player_index)
            echo("build_entity: valid build")
            return
        end
        entityName = event.created_entity.name
        echo("build_entity: " .. entityName .. " invalid build")

        local destroyed = event.created_entity.destroy({ raise_destroy = true })
        echo("build_entity: New entity is " .. (destroyed == true and "destroyed" or "not destroyed"))

        if destroyed then
            game.players[event.player_index].insert({ name = event.item.name, count = 1 })
            echo("build_entity: amount of stored entities = "..count(timg.stored_entities[event.player_index]))
            if count(timg.stored_entities[event.player_index]) ~= 0 then
                echo("build_entity: " .. entityName .. " invalid build, found stored entities, restoring now")
                timg.restore_stored_entities(event.player_index, event)
            end
        end

        timg.events.reset_valid_build(event.player_index)
        echo("build_entity: end")
    end,

    put_item = function(event)
        echo("put_item: begin")
        echo(serpent.block(event))
        local player = game.get_player(event.player_index)
        timg.events.reset_valid_build(event.player_index)

        if not timg.is_active(event.player_index) then
            echo("put_item: TIMG not active")
            return
        elseif player.cursor_stack.valid_for_read == false then
            echo("put_item: cursor stack invalid")
            timg.events.valid_build[event.player_index] = false
            return
        elseif player.cursor_stack.type ~= "item" then
            echo("put_item: cursor stack is not an item")
            return
        end

        local item_dimensions = timg.calculate_item_dimensions(player.cursor_stack.prototype.place_result.selection_box, event.direction, event.position)

        entity_count = timg.count_entities_in_area(item_dimensions.area, player.surface)
        echo("put_item: counted " .. entity_count .. " entities")
        if entity_count == 1 then
            timg.events.valid_build[event.player_index] = timg.check_ghost(player.cursor_stack.prototype.name, event, area)
        elseif entity_count == 0 then
            timg.events.valid_build[event.player_index] = not timg.is_bp_only(pid)
        else
            timg.events.valid_build[event.player_index] = false
        end

        if timg.events.valid_build[event.player_index] == false then
            pid = event.player_index
            echo(event.player_index)
            echo(pid)
            timg.store_entities_in_area(item_dimensions.area, pid)
        end
        echo("put_item: end put_item")
    end,

    toggle = function(event)
        if timg.events.is_map_editor == true then
            return
        end
        player = event.player_index

        if global.active == nil then
            global.active = {}
        end
        if global.active[event.player_index] == nil then
            global.active[event.player_index] = true
        end

        global.active[event.player_index] = not global.active[event.player_index]
        if game.players[event.player_index].is_shortcut_available(timg.events.on_toggle_button) then
            game.players[event.player_index].set_shortcut_toggled(timg.events.on_toggle_button, global.active[event.player_index])
        end
        timg.events.valid_build[event.player_index] = false
    end,

    toggle_blueprint = function(event)
        if timg.events.is_map_editor == true then
            return
        end
        player = event.player_index

        if global.bp_only == nil then
            global.bp_only = {}
        end
        if global.bp_only[event.player_index] == nil then
            global.bp_only[event.player_index] = false
        end

        global.bp_only[event.player_index] = not global.bp_only[event.player_index]
        if game.players[event.player_index].is_shortcut_available(timg.events.on_toggle_bp_button) then
            game.players[event.player_index].set_shortcut_toggled(timg.events.on_toggle_bp_button, global.bp_only[event.player_index])
        end
    end,

    reset_valid_build = function(pid)
        if timg.is_bp_only(pid) then
            timg.events.valid_build[pid] = false
        else
            timg.events.valid_build[pid] = true
        end
        timg.stored_entities[pid] = { }
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
        game.print("There is my ghost is now in '" .. level .. "' debug mode")
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