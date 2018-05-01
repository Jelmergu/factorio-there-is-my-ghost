require("helpers")
require("eventHandlerFunctions")

script.on_event(defines.events.on_put_item, validatePositionedGhost)
--    validatePositionedGhost(event)
--end)

script.on_event(defines.events.on_built_entity, builtOrDestroy)
--    builtOrDestroy (event)
--end)

script.on_event(defines.events.on_player_cursor_stack_changed, rememberCursorStackItemName)

script.on_event(defines.events.on_player_joined_game, playerJoined)

script.on_event(defines.events.on_player_left_game, playerLeft)

script.on_event("there-is-my-ghost-toggle", toggleTIMG)

script.on_event("there-is-my-ghost-blueprint-only", toggleBlueprintOnly)