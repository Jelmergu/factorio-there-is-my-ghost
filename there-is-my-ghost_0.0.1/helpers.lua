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
    for _,v in pairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

function var_dump(table)
    game.print(serpent.block(table))
end