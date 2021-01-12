require "helpers"
require "functions"

script.on_init(timg.events.init)

script.on_configuration_changed(timg.events.on_config_change)

script.on_event(defines.events.on_pre_build, timg.events.put_item)

script.on_event(
        defines.events.on_built_entity,
        timg.events.build_entity,
        {
            {filter="ghost", invert=true, mode="and"},
            {filter="rail", invert=true, mode="and"},
            {filter="rolling-stock", invert=true, mode="and"},
            {filter="vehicle", invert=true, mode="and"},
            {filter="robot-with-logistics-interface", invert=true, mode="and"},
            {filter="type", type="tile", invert=true, mode="and"},
            {filter="type", type="land-mine", invert=true, mode="and"},
            {filter="type", type="unit", invert=true, mode="and"},
            {filter="type", type="unit-spawner", invert=true, mode="and"},
            {filter="type", type="corpse", invert=true, mode="and"},
            {filter="name", name="logistic-train-stop", invert=true, mode="and"},
        })

--script.on_event(defines.events.on_player_cursor_stack_changed, timg.events.stack_change)

script.on_event(timg.events.on_toggle, timg.events.toggle)

script.on_event(timg.events.on_toggle_bp, timg.events.toggle_blueprint)

script.on_event(defines.events.on_lua_shortcut, timg.events.shortcut)

script.on_init(timg.events.init)

script.on_event(defines.events.on_player_toggled_map_editor, timg.events.map_editor_toggle)

commands.add_command("timg_debug", "Toggle There is my Ghosts debug mode. This will print a load of messages when on", timg.events.toggle_debug)