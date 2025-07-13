if Config.devMode then
    function devPrint(...)
        local args = { ... }
        for i = 1, #args do
            if type(args[i]) == "table" then
                args[i] = json.encode(args[i])
            elseif args[i] == nil then
                args[i] = "nil"
            else
                args[i] = tostring(args[i])
            end
        end
        print("^1[DEV MODE] ^4" .. table.concat(args, " ") .. "^0")
    end
else
    function devPrint(...) end
end

function NotifyClient(src, message, type)
    BccUtils.RPC:Notify("bcc-shops:NotifyClient", {
        message = message,
        type = type or "info"
    }, src)
end

function getLevelFromXP(xp)
    return math.floor(xp / 1000)
end

function getPlayerXP(source)
    return VORPcore.getUser(source).getUsedCharacter.xp
end

--[[function getSellPrice(type, name)
    for _, shop in pairs(Config.shops) do
        for _, item in pairs(shop[type]) do
            if item[type == "items" and "itemName" or "weaponName"] == name and item.sellprice then
                return item.sellprice
            end
        end
    end
    return 0
end]] --