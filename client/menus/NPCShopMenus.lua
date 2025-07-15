function OpenNPCBuySellMenu(shopName)
    devPrint("Opening Buy/Sell Menu for NPC store: " .. shopName)
    local NPCbuySellPage = BCCShopsMainMenu:RegisterPage('bcc-shops:buysell')

    NPCbuySellPage:RegisterElement('header', {
        value = shopName,
        slot = "header"
    })

    NPCbuySellPage:RegisterElement('button', {
        label = _U('storeBuyItems'),
        slot = "content"
    }, function()
        OpenBuyMenu(shopName, "npc")
    end)

    NPCbuySellPage:RegisterElement('button', {
        label = _U('storeSellItems'),
        slot = "content"
    }, function()
        OpenSellMenu(shopName, "npc")
    end)

    if IsPlayerAdmin() then
        devPrint("Player is an admin, showing admin options for store: " .. shopName)
        NPCbuySellPage:RegisterElement('button', {
            label = _U('storeAddItems'),
            slot = "content"
        }, function()
            devPrint("Opening Add Items Menu for NPC store: " .. shopName)
            BccUtils.RPC:Call("bcc-shops:FetchNPCInventory", { shopName = shopName }, function(data)
                devPrint("[RPC:Client] FetchInventory callback received for shop: " .. tostring(shopName))

                if not data or not data.inventory then
                    devPrint("[ERROR] Failed to fetch inventory from server for shop: " .. (shopName or "unknown"))
                    return
                end

                devPrint("[RPC:Client] Received " .. tostring(#data.inventory or 0) .. " items from server.")

                OpenAddNPCItemMenuInternal(shopName)
            end)
        end)

        NPCbuySellPage:RegisterElement('button', {
            label = _U('storeEditItems'),
            slot = "content"
        }, function()
            devPrint("Fetching items from DB for edit menu: " .. shopName)

            BccUtils.RPC:Call("bcc-shops:GetItemsForShop", { shopName = shopName }, function(success, result)
                if not success or type(result) ~= "table" then
                    Notify(result or "Failed to fetch items.", "error")
                    return
                end

                local editListPage = BCCShopsMainMenu:RegisterPage('bcc-shops:edititemlist')

                editListPage:RegisterElement('header', {
                    value = _U('selectItemToEdit'),
                    slot = "header"
                })

                for _, item in ipairs(result) do
                    editListPage:RegisterElement('button', {
                        label = item.item_label .. " (" .. item.item_name .. ")",
                        slot = "content"
                    }, function()
                        OpenEditNPCItemMenu(shopName, item)
                    end)
                end

                editListPage:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    OpenNPCBuySellMenu(shopName)
                end)

                BCCShopsMainMenu:Open({ startupPage = editListPage })
            end)

        end)
    else
        devPrint("Player is not an admin, hiding admin options for store: " .. shopName)
    end

    BCCShopsMainMenu:Open({
        startupPage = NPCbuySellPage
    })
end

function OpenAddNPCItemMenuInternal(shopName)
    devPrint("Opening Add Item Menu for NPC store: " .. shopName)
    local addItemPage = BCCShopsMainMenu:RegisterPage('bcc-shops:addnpcitem:page')

    addItemPage:RegisterElement('header', {
        value = _U('addItemTitle') .. ' ' .. shopName,
        slot = "header"
    })

    local itemName, itemLabel = "", ""
    local itemBuyPrice, itemSellPrice, itemBuyStock, itemSellStock = 0, 0, 0, 0
    local selectedCategoryId, itemLevel = "", 0

    -- Fetch categories from server
    local categories = BccUtils.RPC:CallAsync("bcc-shops:GetShopCategories")
    local categoryOptions = {}

    if categories and #categories > 0 then
        for _, cat in ipairs(categories) do
            table.insert(categoryOptions, { text = cat.text or cat.label or "unknown", value = tostring(cat.value) })
        end
        selectedCategoryId = categoryOptions[1].value or "1" -- default to first category
    else
        Notify("No categories found in database!", "error")
        return
    end

    addItemPage:RegisterElement('input', {
        label = _U('itemName'),
        slot = "content",
        type = "text",
        placeholder = _U('enterItemName'),
        default = itemName
    }, function(data) itemName = data.value or "" end)

    TextDisplay = addItemPage:RegisterElement('textdisplay', {
    value = "The item name should be the one from items table db",
    style = {}
    })

    addItemPage:RegisterElement('input', {
        label = _U('itemLabel'),
        slot = "content",
        type = "text",
        placeholder = _U('enterItemLabel'),
        default = itemLabel
    }, function(data) itemLabel = data.value or "" end)

    addItemPage:RegisterElement('input', {
        label = _U('buyPrice'),
        slot = "content",
        type = "number",
        default = itemBuyPrice,
        min = 0
    }, function(data) itemBuyPrice = tonumber(data.value) or 0 end)

    addItemPage:RegisterElement('input', {
        label = _U('sellPrice'),
        slot = "content",
        type = "number",
        default = itemSellPrice,
        min = 0
    }, function(data) itemSellPrice = tonumber(data.value) or 0 end)

    addItemPage:RegisterElement('input', {
        label = _U('buyStock'),
        slot = "content",
        type = "number",
        default = itemBuyStock,
        min = 0
    }, function(data) itemBuyStock = tonumber(data.value) or 0 end)

    addItemPage:RegisterElement('input', {
        label = _U('sellStock'),
        slot = "content",
        type = "number",
        default = itemSellStock,
        min = 0
    }, function(data) itemSellStock = tonumber(data.value) or 0 end)

    addItemPage:RegisterElement('dropdown', {
        label = _U('category'),
        slot = "content",
        options = categoryOptions,
        default = selectedCategoryId
    }, function(data)
        selectedCategoryId = data.value
        devPrint("Selected category_id: " .. selectedCategoryId)
    end)

    addItemPage:RegisterElement('input', {
        label = _U('levelRequired'),
        slot = "content",
        type = "number",
        default = itemLevel,
        min = 0
    }, function(data) itemLevel = tonumber(data.value) or 0 end)

    addItemPage:RegisterElement('line', { slot = "footer", style = {} })

    addItemPage:RegisterElement('button', {
        label = _U('submit'), slot = "footer"
    }, function()
        if itemName ~= "" and itemLabel ~= "" and itemBuyPrice > 0 then
            BccUtils.RPC:Call("bcc-shops:AddItemNPCShop", {
                shopName      = shopName,
                itemLabel     = itemLabel,
                itemName      = itemName,
                quantity      = math.max(itemBuyStock, itemSellStock),
                buyPrice      = itemBuyPrice,
                sellPrice     = itemSellPrice,
                category_id   = tonumber(selectedCategoryId),
                levelRequired = itemLevel,
                buy_quantity  = itemBuyStock,
                sell_quantity = itemSellStock,
            }, function(success, msg)
                if success then
                    Notify(_U('itemAddedSuccess'), "success")
                    BCCShopsMainMenu:Close()
                else
                    Notify(msg or _U('itemAddedFail'), "error")
                end
            end)
        else
            Notify(_U('missingFields'), "error")
            devPrint("Invalid input: " .. itemName .. ", $" .. itemBuyPrice)
        end
    end)

    addItemPage:RegisterElement('button', {
        label = _U('backButton'), slot = "footer"
    }, function()
        OpenNPCBuySellMenu(shopName)
    end)

    addItemPage:RegisterElement('bottomline', { slot = "footer", style = {} })

    BCCShopsMainMenu:Open({ startupPage = addItemPage })
end

function OpenEditNPCItemMenu(shopName, item)
    devPrint("Opening Edit Item Menu for: " .. item.item_name)
    local editPage = BCCShopsMainMenu:RegisterPage('bcc-shops:editnpcitem:page')

    editPage:RegisterElement('header', {
        value = _U('editItemHeader') .. ' ' .. (item.item_label or item.item_name),
        slot = "header"
    })

    local itemLabel     = item.item_label
    local itemBuyPrice  = item.buy_price
    local itemSellPrice = item.sell_price
    local itemBuyStock  = item.buy_quantity
    local itemSellStock = item.sell_quantity
    local itemCategory  = item.category or "default"
    local itemLevel     = item.level_required or 0

    editPage:RegisterElement('input', {
        label = _U('itemLabel'),
        slot = "content",
        type = "text",
        default = itemLabel,
        placeholder = itemLabel
    }, function(data)
        itemLabel = data.value or itemLabel
    end)

    editPage:RegisterElement('input', {
        label = _U('buyPrice'),
        slot = "content",
        type = "number",
        default = itemBuyPrice,
        min = 0,
        placeholder = tostring(itemBuyPrice)
    }, function(data)
        itemBuyPrice = tonumber(data.value) or itemBuyPrice
    end)

    editPage:RegisterElement('input', {
        label = _U('sellPrice'),
        slot = "content",
        type = "number",
        default = itemSellPrice,
        min = 0,
        placeholder = tostring(itemSellPrice)
    }, function(data)
        itemSellPrice = tonumber(data.value) or itemSellPrice
    end)

    editPage:RegisterElement('input', {
        label = _U('buyStock'),
        slot = "content",
        type = "number",
        default = itemBuyStock,
        min = 0,
        placeholder = tostring(itemBuyStock)
    }, function(data)
        itemBuyStock = tonumber(data.value) or itemBuyStock
    end)

    editPage:RegisterElement('input', {
        label = _U('sellStock'),
        slot = "content",
        type = "number",
        default = itemSellStock,
        min = 0,
        placeholder = tostring(itemSellStock)
    }, function(data)
        itemSellStock = tonumber(data.value) or itemSellStock
    end)

    editPage:RegisterElement('input', {
        label = _U('category'),
        slot = "content",
        type = "text",
        default = itemCategory,
        placeholder = itemCategory
    }, function(data)
        itemCategory = data.value or itemCategory
    end)

    editPage:RegisterElement('input', {
        label = _U('RequiredLevel'),
        slot = "content",
        type = "number",
        default = itemLevel,
        min = 0,
        placeholder = tostring(itemLevel)
    }, function(data)
        itemLevel = tonumber(data.value) or itemLevel
    end)

    editPage:RegisterElement('line', { slot = "footer" })

    editPage:RegisterElement('button', {
        label = _U('submitChanges'), slot = "footer"
    }, function()
        BccUtils.RPC:Call("bcc-shops:EditItemNPCShop", {
            shopName      = shopName,
            itemName      = item.item_name,
            itemLabel     = itemLabel,
            buyPrice      = itemBuyPrice,
            sellPrice     = itemSellPrice,
            category      = itemCategory,
            levelRequired = itemLevel,
            buy_quantity  = itemBuyStock,
            sell_quantity = itemSellStock,
        }, function(success, msg)
            if success then
                Notify(_U('itemUpdated'), "success")
                BCCShopsMainMenu:Close()
            else
                Notify(msg or _U('itemUpdateFailed'), "error")
            end
        end)
    end)

    editPage:RegisterElement('button', {
        label = _U('backButton'), slot = "footer"
    }, function()
        OpenNPCBuySellMenu(shopName)
    end)

    editPage:RegisterElement('bottomline', { slot = "footer" })

    BCCShopsMainMenu:Open({ startupPage = editPage })
end

function OpenCreateNPCStoreMenu(npcs)
    local npcStorePage = BCCShopsMainMenu:RegisterPage('bcc-shops:createnpcstore')
    npcStorePage:RegisterElement('header', { value = _U('createNPCStore'), slot = "header" })

    local storeDetails = {
        shopName = '',
        storeType = 'npc',
        shopLocation = '',
        npcPos = nil,
        npcHeading = nil
    }

    npcStorePage:RegisterElement('input',
        { label = _U('storeName'), slot = "content", type = "text", placeholder = _U('fillStoreName') },
        function(data) storeDetails.shopName = data.value end)

    npcStorePage:RegisterElement('input',
        { label = _U('shopLocation'), slot = "content", type = "text", placeholder = _U('fillShopLocation') },
        function(data) storeDetails.shopLocation = data.value end)

    npcStorePage:RegisterElement('button', { label = _U('setCoordinates'), slot = "content" }, function()
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local playerHeading = GetEntityHeading(ped)

        storeDetails.npcPos = playerCoords
        storeDetails.npcHeading = playerHeading

        Notify(_U('coordinatesSet') .. string.format(" (%.2f, %.2f, %.2f, H: %.2f)", playerCoords.x, playerCoords.y, playerCoords.z, playerHeading), "info")
    end)


    npcStorePage:RegisterElement('button', { label = _U('confirmCreateStore'), slot = "footer" }, function()
        if storeDetails.shopName == '' then
            Notify(_U('fillStoreName'), "error")
        elseif storeDetails.shopLocation == '' then
            Notify(_U('fillShopLocation'), "error")
        elseif not storeDetails.npcPos then
            Notify(_U('fillCoordinates'), "error")
        elseif not storeDetails.npcHeading then
            Notify(_U('fillHeading'), "error")
        else
            BccUtils.RPC:Call("bcc-shops:createNPCStore", {
                storeType       = storeDetails.storeType,
                shopName        = storeDetails.shopName,
                shopLocation    = storeDetails.shopLocation,
                posX            = storeDetails.npcPos.x,
                posY            = storeDetails.npcPos.y,
                posZ            = storeDetails.npcPos.z,
                posHeading      = storeDetails.npcHeading
            }, function(success, msg)
                if success then
                    Notify(_U('npcShopAdded'), "success")
                    BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {})
                    BCCShopsMainMenu:Close()
                else
                    Notify(msg or _U('npcShopAddFailed'), "error")
                end
            end)
        end
    end)

    npcStorePage:RegisterElement('button', { label = _U('backButton'), slot = "footer" }, function()
        OpenCreateStoreMenu(npcs)
    end)

    BCCShopsMainMenu:Open({ startupPage = npcStorePage })
end

function OpenDeleteNPCStoresMenu()
    local deleteNPCStoresPage = BCCShopsMainMenu:RegisterPage('bcc-shops:deletenpcstores')
    deleteNPCStoresPage:RegisterElement('header', { 
        value = _U('deleteNPCStores'), 
        slot = "header" 
    })

    for _, store in ipairs(npcStores) do
        deleteNPCStoresPage:RegisterElement('button', { 
            label = store.shop_name, 
            slot = "content" 
        }, function()
            OpenDeleteConfirmationMenu(store.shop_id, store.shop_name, "npc")
        end)
    end

    deleteNPCStoresPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    deleteNPCStoresPage:RegisterElement('button', { 
        label = _U('backButton'), 
        slot = "footer" 
    }, function()
        OpenDeleteStoresMenu()
    end)

    deleteNPCStoresPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })


    BCCShopsMainMenu:Open({ startupPage = deleteNPCStoresPage })
end
