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
        devPrint(("Player is an admin, showing admin options for store: %s"):format(shopName))

        -- Add from player inventory → NPC shop
        NPCbuySellPage:RegisterElement('button', {
            label = _U('storeAddFromInventory'),
            slot  = "content"
        }, function()
            OpenNPCAddFromPlayerInventory(shopName)
        end)

        -- Add manually (your existing form)
        NPCbuySellPage:RegisterElement('button', {
            label = _U('storeAddItems'),
            slot  = "content"
        }, function()
            devPrint(("Opening Add Items (manual) for NPC store: %s"):format(shopName))
            OpenAddNPCItemMenuInternal(shopName)
        end)

        -- Edit Items & Weapons
        NPCbuySellPage:RegisterElement('button', {
            label = _U('storeEditItems'),
            slot  = "content"
        }, function()
            devPrint(("Fetching items+weapons for edit menu: %s"):format(shopName))

            BccUtils.RPC:Call("bcc-shops:GetItemsForShop", { shopName = shopName }, function(success, result)
                if not success or type(result) ~= "table" then
                    Notify(result or _U("failedToFetchItems"), "error", 4000)
                    return
                end

                local editListPage = BCCShopsMainMenu:RegisterPage('bcc-shops:edititemlist:' .. shopName)

                editListPage:RegisterElement('header', {
                    value = _U('selectItemToEdit'),
                    slot  = "header"
                })

                for _, row in ipairs(result) do
                    local label = row.item_label or row.weapon_label or row.item_name or row.weapon_name or "unknown"

                    editListPage:RegisterElement('button', {
                        label = label,
                        slot  = "content"
                    }, function()
                        if row.is_weapon == 1 then
                            OpenEditNPCWeaponMenu(shopName, row)
                        else
                            OpenEditNPCItemMenu(shopName, row)
                        end
                    end)
                end

                editListPage:RegisterElement('line', {
                    slot = "footer"
                })
                editListPage:RegisterElement('button', {
                    label = _U('backButton'),
                    slot  = "footer"
                }, function()
                    OpenNPCBuySellMenu(shopName)
                end)
                editListPage:RegisterElement('bottomline', {
                    slot = "footer"
                })
                BCCShopsMainMenu:Open({ startupPage = editListPage })
            end)
        end)
    else
        devPrint(("Player is not an admin, hiding admin options for store: %s"):format(shopName))
    end

    BCCShopsMainMenu:Open({ startupPage = NPCbuySellPage })
end

function OpenNPCAddFromPlayerInventory(shopName)
    devPrint(("NPC AddFromPlayerInventory for shop: %s"):format(tostring(shopName)))

    local result = BccUtils.RPC:CallAsync("bcc-shops:fetchPlayerInventory", { shopName = shopName })
    if not result then
        devPrint("[ERROR] fetchPlayerInventory returned nil")
        return
    end

    local inventory = result.inventory or {}
    local weapons   = result.weapons or {}

    local page      = BCCShopsMainMenu:RegisterPage('bcc-shops:npc:add_from_player_inv:' .. tostring(shopName))
    page:RegisterElement('header', { value = _U('inventory') .. " → " .. shopName, slot = "header" })
    page:RegisterElement('line', { slot = "header", style = {} })

    local combinedEntries, imageBoxItems = {}, {}
    local idx = 0

    -- ITEMS
    for _, item in ipairs(inventory) do
        local itemName                    = (item.item_name or "unknown_item"):lower()
        local label                       = item.label or item.item_label or _U('unknown')
        local count                       = tonumber(item.count or item.item_quantity or 0) or 0
        local imgPath                     = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png'

        -- normalize fields used by the detail page
        item.is_weapon                    = 0
        item.item_name                    = itemName
        item.label                        = label
        item.count                        = count
        -- description / meta (if inventory system provides them)
        item.custom_desc                  = item.custom_desc or item.description or item.desc or nil
        item.weapon_info                  = item.weapon_info or item.metadata or item.meta or item.info or item.data or
        nil

        idx                               = idx + 1
        combinedEntries[idx]              = item

        imageBoxItems[#imageBoxItems + 1] = {
            type  = "imagebox",
            index = idx,
            data  = {
                img      = imgPath,
                label    = "x" .. count,
                tooltip  = label,
                style    = { margin = "5px" },
                sound    = { action = "SELECT", soundset = "HUD_SHOP" },
                disabled = false
            }
        }
    end

    -- WEAPONS
    for _, weapon in ipairs(weapons) do
        local wName                       = (weapon.name or weapon.weapon_name or "unknown_weapon"):lower()
        local wLabel                      = weapon.custom_label or weapon.label or weapon.weapon_label or _U('unknown')
        local wSerial                     = weapon.serial_number or weapon.serial or "N/A"
        local wId                         = weapon.weaponId or weapon.weapon_id or weapon.id
        local imgPath                     = 'nui://vorp_inventory/html/img/items/' .. wName .. '.png'

        weapon.is_weapon                  = 1
        weapon.item_name                  = wName
        weapon.label                      = wLabel
        weapon.serial_safe                = wSerial
        weapon.weaponId                   = wId
        weapon.count                      = tonumber(weapon.count or 1) or 1
        -- description / meta coming from weapon entry if available
        weapon.custom_desc                = weapon.custom_desc or weapon.description or weapon.desc or nil
        weapon.weapon_info                = weapon.weapon_info or weapon.metadata or weapon.meta or weapon.info or
            weapon.data or nil

        idx                               = idx + 1
        combinedEntries[idx]              = weapon

        imageBoxItems[#imageBoxItems + 1] = {
            type  = "imagebox",
            index = idx,
            data  = {
                img      = imgPath,
                label    = "x" .. weapon.count,
                tooltip  = wLabel .. " | SN: " .. wSerial,
                style    = { margin = "5px" },
                sound    = { action = "SELECT", soundset = "HUD_SHOP" },
                disabled = (wId == nil)
            }
        }
    end

    page:RegisterElement('imageboxcontainer', {
        slot  = "content",
        items = imageBoxItems
    }, function(data)
        local chosen = combinedEntries[data.child.index]
        if not chosen then
            devPrint("[WARN] imagebox click with no matching entry: " .. tostring(data.child.index))
            return
        end
        devPrint(("[ImageBoxContainer] Clicked index=%s -> %s"):format(
            tostring(data.child.index),
            json.encode({ name = chosen.item_name or chosen.name, is_weapon = chosen.is_weapon })
        ))
        OpenNPCAddDetailMenu(shopName, chosen)
    end)

    page:RegisterElement('line', { slot = "footer", style = {} })
    page:RegisterElement('button', { label = _U('backButton'), slot = "footer" }, function()
        OpenNPCBuySellMenu(shopName)
    end)
    page:RegisterElement('bottomline', { slot = "footer", style = {} })

    BCCShopsMainMenu:Open({ startupPage = page })
end

function OpenNPCAddDetailMenu(shopName, entry)
    local isWeapon = (entry.is_weapon == 1 or entry.is_weapon == true)
    local display  = entry.custom_label or entry.label or entry.item_label or entry.item_name or entry.name or
        _U('unknown')
    local owned    = tonumber(entry.count or 0) or 0
    local isAdmin  = (type(IsPlayerAdmin) == "function" and IsPlayerAdmin()) or false

    local page     = BCCShopsMainMenu:RegisterPage('bcc-shops:npc:add_detail:' .. tostring(shopName))
    page:RegisterElement('header', {
        value = display,
        slot  = "header"
    })

    -- categories
    local categories = BccUtils.RPC:CallAsync("bcc-shops:GetShopCategories")
    local categoryOptions, selectedCategoryId = {}, nil
    if categories and #categories > 0 then
        for _, cat in ipairs(categories) do
            categoryOptions[#categoryOptions + 1] = {
                text = cat.text or cat.label or "unknown",
                value = tostring(cat
                    .value)
            }
        end
        selectedCategoryId = tonumber(categoryOptions[1].value)
    end

    local buyPrice, sellPrice, levelReq = 0, 0, 0
    local buyQty, sellQty               = 0, 0
    local currencyType                  = "cash"
    -- Prefill from entry if available
    local customDesc                    = entry.custom_desc or ""
    local weaponInfo                    = entry.weapon_info and
        (type(entry.weapon_info) == "string" and entry.weapon_info or json.encode(entry.weapon_info)) or ""

    local function clampQty(v, maxOwned)
        v = math.max(0, math.floor(tonumber(v) or 0))
        if isAdmin then return v end
        return math.min(v, maxOwned)
    end

    -- Basic pricing
    page:RegisterElement('input', {
        label = _U('buyPrice'),
        placeholder = _U('buyPrice'),
        slot = "content",
        type = "number",
        min = 0
    }, function(d) buyPrice = tonumber(d.value) or 0 end)

    page:RegisterElement('input', {
        label = _U('sellPrice'),
        placeholder = _U('sellPrice'),
        slot = "content",
        type = "number",
        min = 0
    }, function(d) sellPrice = tonumber(d.value) or 0 end)

    -- Separate Buy/Sell stock (admin can exceed owned)
    page:RegisterElement('input', {
        label = _U('buyStock'), -- “Buy stock” to add
        slot  = "content",
        type  = "number",
        min   = 0
    }, function(d)
        buyQty = clampQty(d.value, owned)
    end)

    page:RegisterElement('input', {
        label = _U('sellStock'), -- “Sell stock” to add
        slot  = "content",
        type  = "number",
        min   = 0
    }, function(d)
        sellQty = clampQty(d.value, owned)
    end)

    if #categoryOptions > 0 then
        page:RegisterElement('dropdown', {
            label   = _U('category'),
            slot    = "content",
            options = categoryOptions,
            default = tostring(selectedCategoryId)
        }, function(d) selectedCategoryId = tonumber(d.value) end)
    end

    page:RegisterElement('input', {
        label = _U('levelRequired'),
        slot  = "content",
        type  = "number",
        min   = 0
    }, function(d) levelReq = tonumber(d.value) or 0 end)

    -- Description / meta fields (prefilled)
    if isWeapon then
        page:RegisterElement('input', {
            label   = _U('customDesc'),
            slot    = "content",
            type    = "text",
            default = customDesc
        }, function(d) customDesc = d.value or "" end)

        page:RegisterElement('input', {
            label   = "Weapon Info/Meta (JSON or text)",
            slot    = "content",
            type    = "text",
            default = weaponInfo
        }, function(d) weaponInfo = d.value or "" end)
    else
        -- Optional: also allow description/meta for items if you want to carry them (server ignores by default)
        if customDesc ~= "" or weaponInfo ~= "" then
            page:RegisterElement('html', {
                value = ("<i>%s</i>"):format("Info loaded from item metadata"),
                slot  = "content"
            })
        end
    end

    page:RegisterElement('line', { slot = "footer" })
    page:RegisterElement('button', { label = _U('submit'), slot = "footer" }, function()
        -- basic validation
        if (buyQty <= 0 and sellQty <= 0) or not selectedCategoryId then
            return Notify(_U('missingFields'), "error", 4000)
        end

        if isWeapon then
            local weaponId = entry.weaponId or entry.weapon_id or entry.id
            if not weaponId then
                return Notify(_U("weaponIdMissing") or "No weaponId found on this entry.", "error", 4000)
            end

            -- For weapons, your server RPC only supports a single “quantity” (buy_quantity).
            local payload = {
                shopName      = shopName,
                weaponName    = entry.item_name or entry.name,
                weaponLabel   = display,
                buyPrice      = buyPrice,
                sellPrice     = sellPrice,
                category      = selectedCategoryId,
                levelRequired = levelReq,
                currencyType  = currencyType,
                customDesc    = customDesc,
                weaponInfo    = weaponInfo,
                weaponId      = weaponId,
                quantity      = math.max(buyQty, sellQty) -- server has only one column to increment (buy_quantity)
            }

            devPrint("[NPC Add Weapon] " .. json.encode(payload))
            BccUtils.RPC:Call("bcc-shops:AddWeaponItem", payload, function(success, err)
                if success then
                    Notify(_U('weaponAddedSuccess') or "Weapon added to shop", "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(err or _U('weaponAddedFail') or "Failed to add weapon", "error", 4000)
                end
            end)
        else
            -- ITEMS: send separate buy/sell quantities (see server tweak below)
            local payload = {
                shopName      = shopName,
                itemLabel     = display,
                itemName      = entry.item_name,
                buyPrice      = buyPrice,
                sellPrice     = sellPrice,
                category_id   = selectedCategoryId,
                levelRequired = levelReq,
                buy_quantity  = buyQty,
                sell_quantity = sellQty,
                quantity      = math.max(buyQty, sellQty) -- fallback if server doesn't use the separated fields
            }

            devPrint("[NPC Add Item] " .. json.encode(payload))
            BccUtils.RPC:Call("bcc-shops:AddItemNPCShop", payload, function(success, err)
                if success then
                    Notify(_U('itemAddedSuccess') or "Item added to shop", "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(err or _U('itemAddedFail') or "Failed to add item", "error", 4000)
                end
            end)
        end
    end)

    page:RegisterElement('button', { label = _U('backButton'), slot = "footer" }, function()
        OpenNPCAddFromPlayerInventory(shopName)
    end)

    page:RegisterElement('bottomline', { slot = "footer" })
    BCCShopsMainMenu:Open({ startupPage = page })
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
        Notify(_U("noCategoriesFound"), "error", 4000)
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
            }, function(success)
                if success then
                    Notify(_U('itemAddedSuccess'), "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(_U('itemAddedFail'), "error", 4000)
                end
            end)
        else
            Notify(_U('missingFields'), "error", 4000)
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
        }, function(success)
            if success then
                Notify(_U('itemUpdated'), "success", 4000)
                BCCShopsMainMenu:Close()
            else
                Notify(_U('itemUpdateFailed'), "error", 4000)
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

function OpenEditNPCWeaponMenu(shopName, weapon)
    devPrint("Opening Edit Weapon Menu for: " .. (weapon.weapon_name or weapon.item_name or "unknown_weapon"))

    local editPage = BCCShopsMainMenu:RegisterPage('bcc-shops:editnpcweapon:page:' .. tostring(shopName))

    local wName     = weapon.weapon_name or weapon.item_name or weapon.name or "unknown_weapon"
    local wLabel    = weapon.weapon_label or weapon.item_label or weapon.label or wName
    local buyPrice  = tonumber(weapon.buy_price or 0) or 0
    local sellPrice = tonumber(weapon.sell_price or 0) or 0
    local category  = weapon.category or weapon.category_id or "default"
    local levelReq  = tonumber(weapon.level_required or 0) or 0
    local buyQty    = tonumber(weapon.buy_quantity or 0) or 0
    local sellQty   = tonumber(weapon.sell_quantity or 0) or 0

    -- Header
    editPage:RegisterElement('header', {
        value = (_U('editItemHeader') or "Edit") .. ' ' .. wLabel,
        slot  = "header"
    })

    -- Label
    editPage:RegisterElement('input', {
        label       = _U('itemLabel'),
        slot        = "content",
        type        = "text",
        default     = wLabel,
        placeholder = wLabel
    }, function(data)
        wLabel = data.value or wLabel
    end)

    -- Prices
    editPage:RegisterElement('input', {
        label       = _U('buyPrice'),
        slot        = "content",
        type        = "number",
        default     = buyPrice,
        min         = 0,
        placeholder = tostring(buyPrice)
    }, function(data)
        buyPrice = tonumber(data.value) or buyPrice
    end)

    editPage:RegisterElement('input', {
        label       = _U('sellPrice'),
        slot        = "content",
        type        = "number",
        default     = sellPrice,
        min         = 0,
        placeholder = tostring(sellPrice)
    }, function(data)
        sellPrice = tonumber(data.value) or sellPrice
    end)

    -- Category (text, to match your item editor)
    editPage:RegisterElement('input', {
        label       = _U('category'),
        slot        = "content",
        type        = "text",
        default     = tostring(category),
        placeholder = tostring(category)
    }, function(data)
        category = data.value or category
    end)

    -- Level required
    editPage:RegisterElement('input', {
        label       = _U('RequiredLevel'),
        slot        = "content",
        type        = "number",
        default     = levelReq,
        min         = 0,
        placeholder = tostring(levelReq)
    }, function(data)
        levelReq = tonumber(data.value) or levelReq
    end)

    -- Stock (editable now)
    editPage:RegisterElement('input', {
        label       = _U('buyStock'),
        slot        = "content",
        type        = "number",
        default     = buyQty,
        min         = 0,
        placeholder = tostring(buyQty)
    }, function(data)
        buyQty = math.max(0, math.floor(tonumber(data.value) or buyQty))
    end)

    editPage:RegisterElement('input', {
        label       = _U('sellStock'),
        slot        = "content",
        type        = "number",
        default     = sellQty,
        min         = 0,
        placeholder = tostring(sellQty)
    }, function(data)
        sellQty = math.max(0, math.floor(tonumber(data.value) or sellQty))
    end)

    -- Footer / submit
    editPage:RegisterElement('line', { slot = "footer" })

    editPage:RegisterElement('button', {
        label = _U('submitChanges'),
        slot  = "footer"
    }, function()
        local payload = {
            shopName      = shopName,
            weaponName    = wName,
            weaponLabel   = wLabel,
            buyPrice      = buyPrice,
            sellPrice     = sellPrice,
            category      = category,
            levelRequired = levelReq,
            buy_quantity  = buyQty,
            sell_quantity = sellQty
        }

        devPrint("[Edit Weapon] Payload: " .. json.encode(payload))

        -- This expects the server RPC to accept buy_quantity/sell_quantity (see server snippet below)
        BccUtils.RPC:Call("bcc-shops:EditWeaponItem", payload, function(success, err)
            if success then
                Notify(_U('itemUpdated') or "Weapon updated", "success", 4000)
                BCCShopsMainMenu:Close()
            else
                Notify(err or _U('itemUpdateFailed') or "Failed to update weapon", "error", 4000)
            end
        end)
    end)

    editPage:RegisterElement('button', {
        label = _U('backButton'),
        slot  = "footer"
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

    npcStorePage:RegisterElement('input', {
        label = _U('storeName'),
        slot = "content",
        type = "text",
        placeholder = _U('fillStoreName')
    }, function(data)
        storeDetails.shopName = data.value
    end)

    npcStorePage:RegisterElement('input', {
        label = _U('shopLocation'),
        slot = "content",
        type = "text",
        placeholder = _U('fillShopLocation')
    }, function(data) storeDetails.shopLocation = data.value end)

    npcStorePage:RegisterElement('button', { label = _U('setCoordinates'), slot = "content" }, function()
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local playerHeading = GetEntityHeading(ped)

        storeDetails.npcPos = playerCoords
        storeDetails.npcHeading = playerHeading

        Notify(_U('coordinatesSet') .. playerCoords.x .. playerCoords.y .. playerCoords.z .. playerHeading, "info", 4000)
    end)


    npcStorePage:RegisterElement('button', { label = _U('confirmCreateStore'), slot = "footer" }, function()
        if storeDetails.shopName == '' then
            Notify(_U('fillStoreName'), "error", 4000)
        elseif storeDetails.shopLocation == '' then
            Notify(_U('fillShopLocation'), "error", 4000)
        elseif not storeDetails.npcPos then
            Notify(_U('fillCoordinates'), "error", 4000)
        elseif not storeDetails.npcHeading then
            Notify(_U('fillHeading'), "error", 4000)
        else
            BccUtils.RPC:Call("bcc-shops:createNPCStore", {
                storeType    = storeDetails.storeType,
                shopName     = storeDetails.shopName,
                shopLocation = storeDetails.shopLocation,
                posX         = storeDetails.npcPos.x,
                posY         = storeDetails.npcPos.y,
                posZ         = storeDetails.npcPos.z,
                posHeading   = storeDetails.npcHeading
            }, function(success)
                if success then
                    Notify(_U('npcShopAdded'), "success", 4000)
                    BccUtils.RPC:Notify("bcc-shops:RefreshStoreData", {})
                    BCCShopsMainMenu:Close()
                else
                    Notify(_U('npcShopAddFailed'), "error", 4000)
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
