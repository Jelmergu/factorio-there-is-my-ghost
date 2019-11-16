function round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function in_table(table, item)
    if table == nil then
        return false
    end
    for _, v in pairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

function count(table)
    if table == nil then
        return 0
    end
    local count = 0
    for _, __ in pairs(table) do
        count = count+1
    end
    return count
end


function var_dump(table)
    if timg.debug == timg.debug_levels.none then
        return
    end
    echo(serpent.block(table))
end

function echo(string)
    if timg.debug == timg.debug_levels.none then
        return
    end
    if timg.debug >= timg.debug_levels.log then
        log(string)
    end

    if timg.debug >= timg.debug_levels.message then
        game.print(string)
    end
end