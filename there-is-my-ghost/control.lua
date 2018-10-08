require "helpers"
require "functions"

script.on_init(tigm.events.init)

script.on_configuration_changed(tigm.events.init)

script.on_event(defines.events.on_put_item, tigm.events.put_item)

script.on_event(defines.events.on_built_entity, tigm.events.build_entity)

script.on_event(defines.events.on_player_cursor_stack_changed, tigm.events.stack_change)

script.on_event(tigm.events.on_toggle, tigm.events.toggle)

script.on_event(tigm.events.on_toggle_bp, tigm.events.toggle_blueprint)