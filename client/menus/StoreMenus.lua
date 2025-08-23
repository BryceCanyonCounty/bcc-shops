function BackToMainMenu(shopName)
    local opened = false
    for _, shop in ipairs(globalNearbyShops or {}) do
        if shop.name == shopName then
            if shop.type == "player" then
                OpenPlayerBuySellMenu(shop.name)
                opened = true
                break
            elseif shop.type == "npc" and not opened then
                OpenNPCBuySellMenu(shop.name)
                break
            end
        end
    end
end

function OpenStoreMenu(nearbyShops, filterType)
    if not nearbyShops then
        devPrint("Error: nearbyShops is nil")
        Notify(_U("noNearbyShopsFound"), 4000)
        return
    end

    devPrint("Opening store menu with shops: " .. json.encode(nearbyShops))

    local storePage = BCCShopsMainMenu:RegisterPage('store:main')
    storePage:RegisterElement('header', { value = 'Store Menu', slot = "header" })

    for _, shop in ipairs(nearbyShops) do
        if not filterType or shop.type == filterType then
            storePage:RegisterElement('button', { label = shop.name, slot = "content" }, function()
                if shop.type == "npc" then
                    OpenNPCBuySellMenu(shop.name)
                else
                    OpenPlayerBuySellMenu(shop.name)
                end
            end)
        end
    end

    storePage:RegisterElement('line', { slot = "footer", style = {} })
    storePage:RegisterElement('button', { label = _U('storeClose'), slot = "footer" }, function()
        BCCShopsMainMenu:Close()
    end)
    storePage:RegisterElement('bottomline', { slot = "footer", style = {} })

    BCCShopsMainMenu:Open({ startupPage = storePage })
end

function OpenEditItemMenu(shopName, storeType)
    devPrint("Opening Edit Item Menu for " .. storeType .. " store: " .. shopName)
    if storeType == "npc" then
        -- Logic for editing items in NPC store
    elseif storeType == "player" then
        -- Logic for editing items in Player store
    end
end