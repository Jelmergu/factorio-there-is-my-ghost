local unUsables = {
    items = {
        "rail",
        "rail-planner",
        "straight-rail",
        "logistic-train-stop",
        "land-mine",
    },
    types = {
        "unit",
        "unit-spawner",
        "corpse"
    },
    fast_replacable = {
        "miniloader-inserter"
    }
}

local unReturnables = {
    "miniloader-inserter"
}

return {unUsables, unReturnables}

