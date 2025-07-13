CreatedCustomers = {}

function waitUntilClose(ped, label, meetPoint)
    local timeout = GetGameTimer() + 60000 -- 15 seconds to reach
    local lastPos = GetEntityCoords(ped)
    local stuckCounter = 0

    while #(GetEntityCoords(ped) - vector3(meetPoint.x, meetPoint.y, meetPoint.z)) > 1.5 do
        Wait(1000)

        local currentPos = GetEntityCoords(ped)
        local distMoved = #(vector3(currentPos.x, currentPos.y, currentPos.z) - vector3(lastPos.x, lastPos.y, lastPos.z))

        if distMoved < 0.1 then
            stuckCounter = stuckCounter + 1
        else
            stuckCounter = 0
        end

        lastPos = currentPos

        if GetGameTimer() > timeout or stuckCounter >= 5 then
            devPrint("❌ " .. label .. " is stuck or timeout reached")
            return false
        end
    end

    devPrint("✅ " .. label .. " reached meeting point")
    return true
end

function SpawnConfiguredPed(model, position)
    if not model or not position then
        devPrint("Invalid model or position for SpawnConfiguredPed")
        return nil
    end
    local pedObj = BccUtils.Ped:Create(model, position.x, position.y, position.z, 0.0, "world", true, nil, nil, true, false)
    --local pedObj = BccUtils.Ped:Create(model, position.x, position.y, position.z, 0.0, "world", true, nil, nil, false, false)

    if not pedObj or not pedObj.GetPed then
        devPrint("Failed to create ped with model: " .. tostring(model))
        return nil
    end

    local ped = pedObj:GetPed()

    ClearPedTasks(ped)
    pedObj:SetBlockingOfNonTemporaryEvents(true)
    pedObj:Invincible(true)
    pedObj:Freeze(false)
            
    devPrint(("Spawned ped model '%s' at (%.2f, %.2f, %.2f)"):format(
        model, position.x, position.y, position.z
    ))

    return pedObj
end

function SpawnNPCMeetFromShop(shop, modelA, modelB, deleteDelay)
    local availableLocations = Config.NPC.locations
    local keys = {}

    for k in pairs(availableLocations) do
        table.insert(keys, k)
    end

    if #keys == 0 then
        devPrint("No configured NPC locations in config!")
        return
    end

    local randomKey = keys[math.random(#keys)]
    local location = availableLocations[randomKey]

    devPrint("📍 Selected NPC meet location: " .. randomKey)

    local meetPoint = location.meet
    local spawnA = location.npcA
    local spawnB = location.npcB

    local pedAObj = SpawnConfiguredPed(modelA, spawnA)
    local pedBObj = SpawnConfiguredPed(modelB, spawnB)
    table.insert(CreatedCustomers, pedAObj)
    table.insert(CreatedCustomers, pedBObj)
    if not pedAObj or not pedBObj then
        devPrint("Failed to spawn one or both NPCs, aborting")
        return
    end

    local pedA, pedB = pedAObj:GetPed(), pedBObj:GetPed()

    devPrint("🚶 Tasking both NPCs to walk to meeting point")
    TaskGoToCoordAnyMeans(pedA, meetPoint.x, meetPoint.y, meetPoint.z, 1.0, 0, false, 786603, 0xbf800000)
    TaskGoToCoordAnyMeans(pedB, meetPoint.x, meetPoint.y, meetPoint.z, 1.0, 0, false, 786603, 0xbf800000)

    CreateThread(function()
        if not waitUntilClose(pedA, "Ped A", meetPoint) or not waitUntilClose(pedB, "Ped B", meetPoint) then
            -- Clean up both peds if one failed
            devPrint("🧹 Cleaning up NPCs after failed arrival")
            for _, pedObj in ipairs(CreatedCustomers) do
                if pedObj and pedObj.GetPed and DoesEntityExist(pedObj:GetPed()) then
                    SetPedAsNoLongerNeeded(pedObj:GetPed())
                    pedObj:Remove()
                end
            end
            CreatedCustomers = {}
            return
        end

        devPrint("🤝 Both NPCs at meeting point. Performing interaction...")

        local dir = GetEntityCoords(pedB) - GetEntityCoords(pedA)
        pedAObj:SetHeading(GetHeadingFromVector_2d(dir.x, dir.y))
        pedBObj:SetHeading(GetHeadingFromVector_2d(-dir.x, -dir.y))
        devPrint("🔁 NPCs rotated to face each other")

        local emotes = Config.NPC.emotes
        local selected = emotes[math.random(#emotes)]
        local hash = GetHashKey(selected)
        devPrint("🎭 Selected emote: " .. selected)

        Citizen.InvokeNative(0xB31A277C1AC7B7FF, pedA, 3, 2, hash, 0, 0, 0, 0, 0)
        Citizen.InvokeNative(0xB31A277C1AC7B7FF, pedB, 3, 2, hash, 0, 0, 0, 0, 0)

        Wait(3000)
        devPrint("⏳ Emotes played, starting scenarios...")
        local idleScenarios = Config.NPC.idleScenarios
        local scenarioA = idleScenarios[math.random(#idleScenarios)]
        local scenarioB = idleScenarios[math.random(#idleScenarios)]

        TaskStartScenarioInPlaceHash(pedA, GetHashKey(scenarioA.name), scenarioA.duration, true, 0, -1.0, false)
        TaskStartScenarioInPlaceHash(pedB, GetHashKey(scenarioB.name), scenarioB.duration, true, 0, -1.0, false)

        if shop and shop.items and #shop.items > 0 then
            local item = shop.items[math.random(1, #shop.items)]
            item.item_name = item.name
            item.buy_price = item.price
            local isWeapon = item.is_weapon == 1

            local maxAvailable = tonumber(item.buy_quantity or 1)
            if maxAvailable <= 0 then return end

            -- Weighted quantity pool: rare 4/5
            local quantityPool = {1, 1, 1, 2, 2, 3, 3, 4, 5}
            local desired = quantityPool[math.random(1, #quantityPool)]
            local quantity = math.min(desired, maxAvailable)

            devPrint("NPCs are purchasing item: " .. item.item_name .. " x" .. quantity .. " for $" .. (item.buy_price * quantity))
            ProcessPurchaseNpc(shop.shop_name, item, quantity, isWeapon)
        end

        Wait(7000)
        devPrint("🚶 Both NPCs finished their scenarios, moving to spawn points")
        TaskGoToCoordAnyMeans(pedA, spawnA.x, spawnA.y, spawnA.z, 1.0, 0, false, 786603, 0xbf800000)
        TaskGoToCoordAnyMeans(pedB, spawnB.x, spawnB.y, spawnB.z, 1.0, 0, false, 786603, 0xbf800000)

        Wait(deleteDelay or 20000)
        devPrint("🧹 Cleaning up NPCs")
        for _, pedObj in ipairs(CreatedCustomers) do
            if pedObj and pedObj.GetPed and DoesEntityExist(pedObj:GetPed()) then
                SetPedAsNoLongerNeeded(pedObj:GetPed())
                pedObj:Remove()
            end
        end
        CreatedCustomers = {} -- clear the table after cleanup
        devPrint("All tracked NPCs removed successfully")
    end)
end

RegisterCommand("npcbuyrandomweapon", function()
    local shopName = "Arme si Munitie"
    local quantity = 1

    BccUtils.RPC:Call("bcc-shops:FetchShopItems", { shopName = shopName }, function(result)
        if not result or not result.weapons then
            devPrint("Failed to fetch weapons from shop: " .. shopName)
            return
        end

        -- Flatten the category-grouped weapons table
        local allWeapons = {}
        for _, group in pairs(result.weapons) do
            for _, weapon in ipairs(group) do
                if weapon.buy_quantity and tonumber(weapon.buy_quantity) >= quantity then
                    table.insert(allWeapons, weapon)
                end
            end
        end

        if #allWeapons < 2 then
            devPrint("Not enough weapon stock available to perform test.")
            return
        end

        -- Pick two different weapons
        math.randomseed(GetGameTimer())
        local first = allWeapons[math.random(#allWeapons)]
        local second
        repeat
            second = allWeapons[math.random(#allWeapons)]
        until second.name ~= first.name

        local function purchase(weapon)
            local totalCost = (tonumber(weapon.price) or 0) * quantity
            local payload = {
                shopName = shopName,
                weaponName = weapon.name,
                quantity = quantity,
                total = totalCost
            }

            devPrint("Attempting NPC weapon purchase: " .. json.encode(payload))

            BccUtils.RPC:Call("bcc-shops:PurchaseWeaponNPC", payload, function(success)
                if success then
                    devPrint("NPC successfully bought: " .. weapon.label)
                else
                    devPrint("NPC failed to buy: " .. weapon.label)
                end
            end)
        end

        purchase(first)
        Wait(1000)
        purchase(second)
    end)
end)

RegisterCommand("npcmeetbuy", function()
    BccUtils.RPC:Call("bcc-shops:GetAllPlayerShops", {}, function(shops)
        if not shops or #shops == 0 then return end

        local shop = shops[math.random(#shops)]
        shop.pos_x = tonumber(shop.pos_x)
        shop.pos_y = tonumber(shop.pos_y)
        shop.pos_z = tonumber(shop.pos_z)
        if not shop.pos_x or not shop.pos_y or not shop.pos_z then
            devPrint("Missing or invalid coordinates in selected shop!")
            return
        end

        shop.coords = vector3(shop.pos_x, shop.pos_y, shop.pos_z)
        devPrint("📦 Selected random shop for NPC meet: " .. shop.shop_name .. " at coords: " .. tostring(shop.coords))

        BccUtils.RPC:Call("bcc-shops:FetchShopItems", { shopName = shop.shop_name }, function(result)
            if not result then
                devPrint("[NPC] Failed to fetch shop data for: " .. shop.shop_name)
                return
            end

            local allItems = {}

            for _, group in pairs(result.items or {}) do
                for _, i in ipairs(group) do
                    if i.buy_quantity and i.buy_quantity > 0 then
                        table.insert(allItems, i)
                    end
                end
            end

            for _, group in pairs(result.weapons or {}) do
                for _, i in ipairs(group) do
                    if i.buy_quantity and i.buy_quantity > 0 then
                        i.is_weapon = 1 -- flag it
                        table.insert(allItems, i)
                    end
                end
            end

            if #allItems == 0 then
                devPrint("[NPC] No purchasable items or weapons with stock for shop: " .. shop.shop_name)
                return
            end

            shop.items = allItems


            local modelA = Config.NPC.npcModels[math.random(#Config.NPC.npcModels)]
            local modelB = Config.NPC.npcModels[math.random(#Config.NPC.npcModels)]
            while modelB == modelA do
                modelB = Config.NPC.npcModels[math.random(#Config.NPC.npcModels)]
            end

            SpawnNPCMeetFromShop(shop, modelA, modelB, 50000)
        end)
    end)
end)