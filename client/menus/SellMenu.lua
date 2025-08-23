function SellMenu(shopName)
    devPrint("🟢 Entered SellMenu for shop: " .. tostring(shopName))
    BccUtils.RPC:Call("bcc-shops:GetShopItems", { shopName = shopName }, function(data)
        if (not data.items or next(data.items) == nil) and (not data.weapons or next(data.weapons) == nil) then
            Notify(_U("shop_no_items_found_tosell"), "error", 4000)
            return
        end

        local validCategories = {}
        local categoryTypeMap = {}
        local categoryLabelMap = {}

        local function hasValidItems(entries)
            for _, item in ipairs(entries or {}) do
                if item.sell_price and item.sell_price > 0 then
                    return true
                end
            end
            return false
        end

        -- Collect valid item categories
        for categoryId, entries in pairs(data.items or {}) do
            if hasValidItems(entries) then
                table.insert(validCategories, categoryId)
                categoryTypeMap[categoryId] = "item"
                categoryLabelMap[categoryId] = entries._label or tostring(categoryId)
            end
        end

        -- Collect valid weapon categories
        for categoryId, entries in pairs(data.weapons or {}) do
            if hasValidItems(entries) then
                table.insert(validCategories, categoryId)
                categoryTypeMap[categoryId] = "weapon"
                categoryLabelMap[categoryId] = entries._label or tostring(categoryId)
            end
        end

        table.sort(validCategories)

        if #validCategories == 0 then
            Notify(_U("shop_no_items_found_tosell"), "warning", 4000)
            return
        end

        local totalPages = #validCategories
        local currentPage = 1

        local function generateHtmlContent(item, imgPath)
            local label = item.label or item.name
            local price = "$" .. (item.sell_price or 0)
            local level = "Lvl " .. (item.level or 0)

            return '<div style="display: flex; align-items: center; width: 100%;">'
                .. '<img src="' .. imgPath .. '" style="width: 38px; height: 38px; margin-right: 10px;">'
                .. '<div style="flex-grow: 1;">'
                .. '<div style="font-weight: bold;">' .. label .. '</div>'
                .. '<div style="font-size: 13px;">' .. level .. '</div>'
                .. '</div>'
                .. '<div style="text-align: right; min-width: 60px;">' .. price .. '</div>'
                .. '</div>'
        end

        local function renderPage()
            local categoryId = validCategories[currentPage]
            local type = categoryTypeMap[categoryId]
            local entries = type == "item" and data.items[categoryId] or data.weapons[categoryId]
            local label = categoryLabelMap[categoryId]

            local sellPage = BCCShopsMainMenu:RegisterPage('sellitems:category:' .. categoryId)
            sellPage:RegisterElement('header', { value = shopName, slot = "header" })
            sellPage:RegisterElement('line', { slot = "header", style = {} })

            sellPage:RegisterElement("subheader", {
                value = (type == "weapon" and "🔫 " or "🔹 ") .. label,
                style = {
                    fontSize = "20px",
                    bold = true,
                    marginBottom = "5px",
                    textAlign = "center"
                },
                slot = "content",
            })

            local hasSellableItems = false

            for _, item in ipairs(entries) do
                if item.sell_price and item.sell_price > 0 then
                    hasSellableItems = true
                    local imgPath = "nui://vorp_inventory/html/img/items/" .. item.name:lower() .. ".png"
                    local html = generateHtmlContent(item, imgPath)

                    sellPage:RegisterElement('button', {
                        html = html,
                        slot = "content"
                    }, function()
                        RequestSellQuantity({
                            item_name      = item.name,
                            item_label     = item.label,
                            sell_price     = item.sell_price,
                            level_required = item.level,
                            sell_quantity  = item.sell_quantity
                        }, shopName, type == "weapon")
                    end)
                end
            end

            if not hasSellableItems then
                sellPage:RegisterElement("text", {
                    value = _U("noSellableItemsInCategory"),
                    style = {
                        fontSize = "16px",
                        color = "#bbb",
                        textAlign = "center",
                        marginTop = "10px"
                    },
                    slot = "content"
                })
            end
            -- Page arrows
            sellPage:RegisterElement('pagearrows', {
                slot = "footer",
                total = totalPages,
                current = currentPage,
                style = {}
            }, function(data)
                if data.value == 'forward' then
                    currentPage = math.min(currentPage + 1, totalPages)
                elseif data.value == 'back' then
                    currentPage = math.max(currentPage - 1, 1)
                end
                renderPage()
            end)

            sellPage:RegisterElement('line', { slot = "footer", style = {} })
            sellPage:RegisterElement('button', {
                label = _U("BackToStores"),
                slot = "footer"
            }, function()
                BackToMainMenu(shopName)
            end)
            sellPage:RegisterElement('bottomline', { slot = "footer", style = {} })

            BCCShopsMainMenu:Open({ startupPage = sellPage })
        end

        renderPage()
    end)
end

function RequestSellQuantity(item, shopName, isWeapon)
    devPrint("RequestSellQuantity called for item: " .. item.item_name)

    local playerLevel = BccUtils.RPC:CallAsync("bcc-shops:GetPlayerLevel", {})
    devPrint("Received player level: " .. playerLevel)

    if item.level_required > playerLevel then
        Notify("You need to be level " .. item.level_required .. " to sell this " .. (isWeapon and "weapon" or "item") .. ".", "error", 4000)
        return
    end

    devPrint("Requesting item count from server via RPC")
    local countItem = BccUtils.RPC:CallAsync("bcc-shops:GetItemCount", {
        item = item.item_name,
        percentage = 100
    })

    devPrint("RPC responded with item count: " .. tostring(countItem))

    if not countItem or countItem <= 0 then
        Notify(_U("no_items_to_sell"), "error")
        return
    end

    local inputPage = BCCShopsMainMenu:RegisterPage('entry:quantity')
    local quantity = 1
    local imgPath = "nui://vorp_inventory/html/img/items/" .. item.item_name .. ".png"

    local html = [[
        <div style="margin: auto; padding: 20px 30px;">
            <div style="display: flex; gap: 20px; align-items: flex-start; margin-bottom: 20px;">
                <div style="flex-shrink: 0;">
                    <img src="]] .. imgPath .. [[" alt="]] .. item.item_label .. [[" style="width: 100px; height: 100px; border: 1px solid #bbb; border-radius: 6px;">
                </div>
                <table style="flex-grow: 1; width: 100%; border-collapse: collapse; font-size: 16px;">
                    <tr style="border-bottom: 1px solid #ddd;">
                        <td style="padding: 6px 10px;">🔒 ]] .. _U("RequiredLevel") .. [[</td>
                        <td style="padding: 6px 10px; color: #2a9d8f;">]] .. item.level_required .. [[</td>
                    </tr>
                    <tr style="border-bottom: 1px solid #ddd;">
                        <td style="padding: 6px 10px;">💸 Sell Price</td>
                        <td style="padding: 6px 10px; color: #e76f51;">$]] .. item.sell_price .. [[</td>
                    </tr>
                    <tr style="border-bottom: 1px solid #ddd;">
                        <td style="padding: 6px 10px;">📦 Shop Stock</td>
                        <td style="padding: 6px 10px; color: #e76f51;">]] .. (item.sell_quantity or 0) .. [[</td>
                    </tr>
                    <tr>
                        <td style="padding: 6px 10px;">🎒 Your Quantity</td>
                        <td style="padding: 6px 10px; color: #6c757d;">]] .. countItem .. [[</td>
                    </tr>
                </table>
            </div>
        </div>
    ]]

    inputPage:RegisterElement('header', { value = shopName, slot = "header" })
    inputPage:RegisterElement('html', { value = { html }, slot = "header" })
    inputPage:RegisterElement('line', { slot = "header", style = {} })

    inputPage:RegisterElement('input', {
        label = _U('storeQty'),
        slot = "content",
        type = "number",
        default = 1,
        min = 1,
        max = countItem
    }, function(data)
        local inputQty = tonumber(data.value)
        if inputQty and inputQty > 0 and inputQty <= countItem then
            quantity = inputQty
            devPrint("Quantity updated: " .. quantity)
        else
            devPrint("Invalid quantity entered: " .. tostring(inputQty))
            quantity = nil
        end
    end)

    inputPage:RegisterElement('line', { slot = "footer", style = {} })
    inputPage:RegisterElement('button', {
        label = _U('storeSell'),
        slot = "footer",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if quantity then
            devPrint("Proceeding with sale of quantity: " .. quantity)
            ProcessSale(shopName, item, quantity, isWeapon)
            SellMenu(shopName)
        else
            Notify("Enter a valid quantity", "error", 4000)
            devPrint("Attempted sale with invalid quantity")
        end
    end)

    inputPage:RegisterElement('button', {
        label = _U('BackToItems'),
        slot = "footer",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        SellMenu(shopName)
    end)

    inputPage:RegisterElement('bottomline', { slot = "footer", style = {} })
    BCCShopsMainMenu:Open({ startupPage = inputPage })
end

function ProcessSale(shopName, item, quantity, isWeapon)
    if not item or not item.item_name then
        devPrint("Invalid item object")
        return
    end

    if not item.sell_price then
        devPrint("Item has no sell price: " .. item.item_name)
        return
    end

    if not quantity or quantity <= 0 then
        Notify(_U("invalidQuantityInput"), "error", 4000)
        devPrint("Invalid quantity for sale: " .. tostring(quantity))
        return
    end

    local totalCost = item.sell_price * quantity
    devPrint("Processing sale for item: " .. item.item_name .. ", Quantity: " .. quantity .. ", Total: " .. totalCost)

    BccUtils.RPC:Call("bcc-shops:SellItem", {
        shopName = shopName,
        itemName = item.item_name,
        quantity = quantity,
        total = totalCost,
        isWeapon = isWeapon
    })
end