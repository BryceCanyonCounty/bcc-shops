function CreateBlips()
    for _, shop in ipairs(npcStores) do
        if shop.show_blip then
            local hash = tonumber(shop.blip_hash)
            local blip = BccUtils.Blips:SetBlip(shop.shop_name, hash, 1, shop.pos_x, shop.pos_y, shop.pos_z)
            CreatedBlip[#CreatedBlip + 1] = blip
        end
    end

    for _, shop in ipairs(playerStores) do
        if shop.show_blip then
            local hash = tonumber(shop.blip_hash)
            local blip = BccUtils.Blips:SetBlip(shop.shop_name, hash, 1, shop.pos_x, shop.pos_y, shop.pos_z)
            CreatedBlip[#CreatedBlip + 1] = blip
        end
    end
end

function CreateNPCs()
    local function createNPCForShop(shop)
        if shop.npc_model and shop.npc_model ~= "" then
            --devPrint("Creating NPC for shop: " .. tostring(shop.shop_name))
            --devPrint("NPC Data:")
            --devPrint("  Model: " .. tostring(shop.npc_model))
            --devPrint("  Position: x=" .. tostring(shop.pos_x) .. ", y=" .. tostring(shop.pos_y) .. ", z=" .. tostring(shop.pos_z))
            ---devPrint("  Heading: " .. tostring(shop.pos_heading))
            --devPrint("  npc_model: " .. tostring(shop.npc_model))

            local ped = BccUtils.Ped:Create(
                shop.npc_model,
                shop.pos_x,
                shop.pos_y,
                shop.pos_z - 1,
                shop.pos_heading or 0.0,
                'world',
                false
            )

            if ped then
                CreatedNPC[#CreatedNPC + 1] = ped
                ped:Freeze()
                ped:SetHeading(shop.pos_heading or 0.0)
                ped:Invincible()
                ped:SetBlockingOfNonTemporaryEvents(true)
            else
                devPrint("Failed to create NPC for shop: " .. tostring(shop.shop_name))
            end
        else
            devPrint("Skipping shop: " .. tostring(shop.shop_name) .. " — Missing or empty npc_model")
        end
    end

    for _, shop in ipairs(npcStores) do
        createNPCForShop(shop)
    end

    for _, shop in ipairs(playerStores) do
        createNPCForShop(shop)
    end
end

function FetchPlayersForOwnerSelection()
    BccUtils.RPC:Call("bcc-shops:FetchPlayersForOwnerSelection", {}, function(players)
        if players then
            -- Replace this with your menu or logic handler
            SelectOwner(players)
        else
            Notify("Failed to fetch players.", "error")
        end
    end)
end

BccUtils.RPC:Register("bcc-shops:clientCleanup", function()
    for _, npc in ipairs(CreatedNPC) do
        if npc and npc.Remove then
            npc:Remove()
        elseif DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    CreatedNPC = {}

    for _, blip in ipairs(CreatedBlip) do
        if blip and blip.Remove then
            blip:Remove()
        else
            RemoveBlip(blip)
        end
    end
    CreatedBlip = {}

    for _, customer in ipairs(CreatedCustomers or {}) do
        if customer and customer.Remove then
            customer:Remove()
        elseif DoesEntityExist(customer) then
            DeleteEntity(customer)
        end
    end
    CreatedCustomers = {}

    BCCShopsMainMenu:Close()

    devPrint("[ClientCleanup] All NPCs, blips, and customers cleaned up.")
end)

BccUtils.RPC:Register("bcc-shops:RefreshStoreData", function(_, cb)
    -- Fetch NPC shops
    npcStores = BccUtils.RPC:CallAsync("bcc-shops:FetchNPCShops")
    devPrint("NPC shops refreshed: " .. tostring(#npcStores))

    -- Fetch player shops (ensure assignment always happens)
    playerStores = BccUtils.RPC:CallAsync("bcc-shops:FetchPlayerShops")
    storesFetched = true
    devPrint("Player stores refreshed: " .. tostring(#playerStores))

    -- Recreate world data
    CreateBlips()
    CreateNPCs()

    if cb then cb(true) end
end)