data:extend({
    {
        type = "custom-input",
        name = "there-is-my-ghost-toggle",
        key_sequence = "CONTROL + G",
    },
    {
        type = "custom-input",
        name = "there-is-my-ghost-blueprint-only",
        key_sequence = "CONTROL + SHIFT + B",
    },
    {
        type = "shortcut",
        name = "there-is-my-ghost-blueprint-only-shortcut",
        order = "zzz",
        action = "lua",
        toggleable = true,
        icon =
        {
            filename = "__there-is-my-ghost__/icons/bp-only-button.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 1,
            flags = { "icon" }
        },
        small_icon =
        {
            filename = "__there-is-my-ghost__/icons/bp-only-button-x24.png",
            priority = "extra-high-no-scale",
            size = 24,
            scale = 1,
            flags = {"icon"}
        },
        disabled_small_icon =
        {
            filename = "__there-is-my-ghost__/icons/bp-only-button-x24-white.png",
            priority = "extra-high-no-scale",
            size = 24,
            scale = 1,
            flags = {"icon"}
        },
    },
    {
        type = "shortcut",
        name = "there-is-my-ghost-toggle-shortcut",
        order = "zzz",
        action = "lua",
        toggleable = true,
        icon =
        {
            filename = "__there-is-my-ghost__/icons/toggle-button.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 1,
            flags = { "icon" }
        },
        small_icon =
        {
            filename = "__there-is-my-ghost__/icons/toggle-button-x24.png",
            priority = "extra-high-no-scale",
            size = 24,
            scale = 1,
            flags = {"icon"}
        },
        disabled_small_icon =
        {
            filename = "__there-is-my-ghost__/icons/toggle-button-x24-white.png",
            priority = "extra-high-no-scale",
            size = 24,
            scale = 1,
            flags = {"icon"}
        }

    }
})