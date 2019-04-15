local intermod = {}

intermod.intermodCompat = function (input)
    if string.find(input, "miniloader", 1, true) then
        return timg.intermod.miniloader(input)
    end
    return input
end

intermod.miniloader = function (input)
    local miniloaders = {
        ["miniloader"] = "miniloader-inserter",
        ["fast-miniloader"] = "fast-miniloader-inserter",
        ["express-miniloader"] = "express-miniloader-inserter",
        ["turbo-miniloader"] = "turbo-miniloader-inserter",
        ["ultimate-miniloader"] = "ultimate-miniloader-inserter",
        ["rapid-mk1-miniloader"] = "rapid-mk1-miniloader-inserter",
        ["rapid-mk2-miniloader"] = "rapid-mk2-miniloader-inserter",
        ["ub-ultra-fast-miniloader"] = "ub-ultra-fast-miniloader-inserter",
        ["ub-extreme-fast-miniloader"] = "ub-extreme-fast-miniloader-inserter",
        ["ub-ultra-express-miniloader"] = "ub-ultra-express-miniloader-inserter",
        ["ub-extreme-express-miniloader"] = "ub-extreme-express-miniloader-inserter",
        ["ub-ultimate-miniloader"] = "ub-ultimate-miniloader-inserter",
        ["expedited-miniloader"] = "expedited-miniloader-inserter",
    }
    for k, v in pairs(miniloaders) do
        if v == input then
            return k
        end
    end
    return input
end

return intermod