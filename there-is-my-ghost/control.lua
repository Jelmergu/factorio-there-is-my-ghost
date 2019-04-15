require "helpers"
require "functions"


script.on_init(timg.events.init)

script.on_configuration_changed(timg.events.on_config_change)

script.on_event(defines.events.on_put_item, timg.events.put_item)

script.on_event(defines.events.on_built_entity, timg.events.build_entity)

script.on_event(defines.events.on_player_cursor_stack_changed, timg.events.stack_change)

script.on_event(timg.events.on_toggle, timg.events.toggle)

script.on_event(timg.events.on_toggle_bp, timg.events.toggle_blueprint)

script.on_event(defines.events.on_lua_shortcut, timg.events.shortcut)

script.on_init(timg.events.init)

script.on_event(defines.events.on_player_toggled_map_editor, timg.events.map_editor_toggle)

commands.add_command("timg_debug", "Toggle There is my Ghosts debug mode. This will print a load of messages when on", timg.events.toggle_debug)