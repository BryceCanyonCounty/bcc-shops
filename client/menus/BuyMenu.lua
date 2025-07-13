function BuyMenu(shopName, returnPage)
    BccUtils.RPC:Call("bcc-shops:GetShopItems", {
        shopName = shopName
    }, function(data)
        if (not data.items or next(data.items) == nil) and (not data.weapons or next(data.weapons) == nil) then
            Notify(_U("shop_no_items_found"), "error")
            return
        end

        local allCategories = {}
        local categoryTypeMap = {}
        local categoryLabelMap = {}

        for categoryId, entries in pairs(data.items or {}) do
            table.insert(allCategories, categoryId)
            categoryTypeMap[categoryId] = "item"
            categoryLabelMap[categoryId] = entries._label or (categoryId)
        end

        for categoryId, entries in pairs(data.weapons or {}) do
            table.insert(allCategories, categoryId)
            categoryTypeMap[categoryId] = "weapon"
            categoryLabelMap[categoryId] = entries._label or (categoryId)
        end

        table.sort(allCategories)
        local totalPages = #allCategories
        local currentPage = returnPage or 1

        local function generateHtmlContent(item, imgPath, unavailable)
            local label = item.label or item.name
            local price = item.price and item.price > 0 and ("$" .. item.price) or _U("unavailable")
            local style = unavailable and 'opacity: 0.5; cursor: not-allowed;' or ''
            return '<div style="display: flex; align-items: center; width: 100%;' .. style .. '">' ..
                '<img src="' .. imgPath .. '" style="width: 38px; height: 38px; margin-right: 10px;">' ..
                '<div style="flex-grow: 1; text-align: center;">' .. label .. '</div>' ..
                '<div style="text-align: right; min-width: 60px;">' .. price .. '</div>' ..
                '</div>'
        end

        local function renderPage()
            local categoryId = allCategories[currentPage]
            local type = categoryTypeMap[categoryId]
            local entries = type == "item" and data.items[categoryId] or data.weapons[categoryId]
            local label = categoryLabelMap[categoryId]

            local buyPage = BCCShopsMainMenu:RegisterPage('buyitems:category:' .. categoryId)
            buyPage:RegisterElement('header', { value = shopName, slot = "header" })
            buyPage:RegisterElement('line', { slot = "header", style = {} })

            buyPage:RegisterElement("subheader", {
                value = (type == "weapon" and "🔫 " or "🔹 ") .. label,
                style = { fontSize = "20px", bold = true, marginBottom = "5px", textAlign = "center" },
                slot = "content",
            })

            for _, item in ipairs(entries) do
                local imgName = item.name:lower()
                local imgPath = "nui://vorp_inventory/html/img/items/" .. imgName .. ".png"
                local isUnavailable = not item.price or item.price <= 0

                local html = generateHtmlContent(item, imgPath, isUnavailable)

                buyPage:RegisterElement('button', {
                    html = html,
                    slot = "content",
                    disabled = isUnavailable
                }, function()
                    if not isUnavailable then
                        RequestBuyQuantity({
                            item_name      = item.name,
                            item_label     = item.label,
                            buy_price      = item.price,
                            level_required = item.level,
                            buy_quantity   = item.buy_quantity
                        }, shopName, type == "weapon", currentPage)
                    end
                end)
            end

            buyPage:RegisterElement('pagearrows', {
                slot = "footer",
                total = totalPages,
                current = currentPage,
                style = {},
            }, function(data)
                if data.value == 'forward' then
                    currentPage = math.min(currentPage + 1, totalPages)
                elseif data.value == 'back' then
                    currentPage = math.max(currentPage - 1, 1)
                end
                renderPage()
            end)

            buyPage:RegisterElement('line', { slot = "footer", style = {} })
            buyPage:RegisterElement('button', {
                label = _U("BackToStores"),
                slot = "footer"
            }, function()
                BackToMainMenu(shopName)
            end)

            buyPage:RegisterElement('bottomline', { slot = "footer", style = {} })
            BCCShopsMainMenu:Open({ startupPage = buyPage })
        end

        renderPage()
    end)
end

function RequestBuyQuantity(item, shopName, isWeapon, returnPage)
    local level = BccUtils.RPC:CallAsync("bcc-shops:GetPlayerLevel", {})

    playerLevel = level

    if item.level_required > playerLevel then
        Notify(
            "You need to be level " ..
            item.level_required .. " to purchase this " .. (isWeapon and "weapon" or "item") .. ".", "error")
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
                    <td style="padding: 6px 10px;">💰 ]] .. _U("Price") .. [[</td>
                    <td style="padding: 6px 10px; color: #e76f51;">$]] .. item.buy_price .. [[</td>
                </tr>
                <tr>
                    <td style="padding: 6px 10px;">📦 ]] .. _U("StockAvailable") .. [[</td>
                    <td style="padding: 6px 10px; color: #6c757d;">]] .. item.buy_quantity .. [[</td>
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
        max = item.buy_quantity or 1
    }, function(data)
        quantity = tonumber(data.value) or 1
    end)

    inputPage:RegisterElement('line', { slot = "footer", style = {} })
    inputPage:RegisterElement('button', {
        label = _U('storeBuy'),
        slot = "footer",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if quantity then
            ProcessPurchase(shopName, item, quantity, isWeapon)
            BuyMenu(shopName, returnPage)
        end
    end)

    inputPage:RegisterElement('button', {
        label = _U('BackToItems'),
        slot = "footer",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        BuyMenu(shopName, returnPage)
    end)

    inputPage:RegisterElement('bottomline', { slot = "footer", style = {} })
    BCCShopsMainMenu:Open({ startupPage = inputPage })
end

function ProcessPurchase(shopName, item, quantity, isWeapon)
    devPrint("Entering ProcessPurchase function for shop: " .. shopName)

    if not item or type(item) ~= "table" then
        devPrint("Invalid item passed to ProcessPurchase")
        devPrint("Item data: " .. tostring(item))
        return
    end

    if not item.item_name then
        devPrint("item.item_name is nil in ProcessPurchase")
        devPrint("Item contents: " .. json.encode(item))
        return
    end

    devPrint("Item details: " .. item.item_name .. ", Quantity: " .. quantity .. ", Is Weapon: " .. tostring(isWeapon))
    local totalCost = item.buy_price * quantity
    devPrint("Calculated total cost: " .. totalCost)

    if quantity and quantity > 0 then
        devPrint("Quantity is valid, proceeding with purchase process.")

        if isWeapon then
            devPrint("Item is a weapon, calling PurchaseWeapon RPC.")
            BccUtils.RPC:Call("bcc-shops:PurchaseWeapon", {
                shopName = shopName,
                weaponName = item.item_name,
                quantity = quantity,
                total = totalCost
            }, function(success)
                if success then
                    devPrint("Weapon purchase successful.")
                else
                    devPrint("Weapon purchase failed.")
                end
            end)
        else
            devPrint("Item is not a weapon, calling PurchaseItem RPC.")
            BccUtils.RPC:Call("bcc-shops:PurchaseItem", {
                shopName = shopName,
                itemName = item.item_name,
                quantity = quantity,
                total = totalCost
            }, function(success)
                if success then
                    devPrint("Item purchase successful.")
                else
                    devPrint("Item purchase failed.")
                end
            end)
        end
    else
        VORPcore.NotifyObjective("Invalid quantity. Purchase request not sent.")
        devPrint("Invalid quantity for purchase: " .. tostring(quantity))
    end
end

function ProcessPurchaseNpc(shopName, item, quantity, isWeapon)
    devPrint("Entering ProcessPurchaseNpc for shop: " .. tostring(shopName))

    if not item or type(item) ~= "table" then
        devPrint("Invalid item passed to ProcessPurchaseNpc")
        devPrint("Item data: " .. tostring(item))
        return
    end

    local itemName = item.item_name or item.name
    if not itemName then
        devPrint("item.item_name is nil in ProcessPurchaseNpc")
        devPrint("Item contents: " .. json.encode(item))
        return
    end

    local buyPrice = item.buy_price or item.price or 0
    local totalCost = buyPrice * quantity

    devPrint("Item: " .. itemName .. ", Quantity: " .. quantity .. ", Total: " .. totalCost .. ", IsWeapon: " .. tostring(isWeapon))

    if quantity and quantity > 0 then
        local rpcName = isWeapon and "bcc-shops:PurchaseWeaponNPC" or "bcc-shops:PurchaseItemNPC"
        local payload = {
            shopName = shopName,
            quantity = quantity,
            total = totalCost
        }

        -- Use appropriate key
        if isWeapon then
            payload.weaponName = itemName
        else
            payload.itemName = itemName
        end

        devPrint("Calling RPC: " .. rpcName .. " with payload: " .. json.encode(payload))

        BccUtils.RPC:Call(rpcName, payload, function(success)
            if success then
                devPrint("Purchase successful for: " .. itemName)
            else
                devPrint("Purchase failed for: " .. itemName)
            end
        end)
    else
        devPrint("Invalid quantity for purchase: " .. tostring(quantity))
    end
end
