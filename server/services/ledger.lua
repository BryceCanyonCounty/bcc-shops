BccUtils.RPC:Register("bcc-shops:ModifyLedger", function(params, cb, src)
    local shopName = params.shopName
    local amount = tonumber(params.amount)
    local action = params.action -- "add" or "remove"

    if not shopName or not amount or amount <= 0 or (action ~= "add" and action ~= "remove") then
        devPrint("Invalid parameters for ModifyLedger")
        return cb(false)
    end

    local user = VORPcore.getUser(src)
    local character = user and user.getUsedCharacter
    if not character then
        devPrint("Character not found for source: " .. tostring(src))
        return cb(false)
    end

    local charId = character.charIdentifier
    local firstname, lastname = character.firstname, character.lastname

    local result = MySQL.query.await([[
        SELECT shop_id, ledger, webhook_link
        FROM bcc_shops
        WHERE shop_name = ? AND owner_id = ?
    ]], { shopName, charId })

    if not result or not result[1] then
        devPrint("Shop not found or not owned by character " .. charId)
        return cb(false)
    end

    local shop = result[1]
    local shopId = shop.shop_id
    local currentLedger = shop.ledger or 0

    if action == "add" then
        if character.money < amount then
            devPrint("Not enough player money. Has: " .. character.money .. ", needs: " .. amount)
            NotifyClient(src, _U("notEnoughMoney"), "error", 4000)
            return cb(false)
        end

        character.removeCurrency(0, amount)
        currentLedger = currentLedger + amount

    elseif action == "remove" then
        if currentLedger < amount then
            devPrint("Not enough money in ledger to withdraw.")
            NotifyClient(src, _U("notEnoughLedgerFunds"), "error", 4000)
            return cb(false)
        end

        character.addCurrency(0, amount)
        currentLedger = currentLedger - amount
    end

    local success = MySQL.update.await(
        "UPDATE bcc_shops SET ledger = ? WHERE shop_id = ?",
        { currentLedger, shopId }
    )

    if not success or success <= 0 then
        devPrint("Ledger update failed.")
        return cb(false)
    end

    -- Webhook Logging
    local message = {{
        color = (action == "add") and 65280 or 16711680, -- green or red
        title = (action == "add") and "💵 Money Added to Ledger" or "💸 Money Removed from Ledger",
        description = table.concat({
            "**Character:** `" .. firstname .. " " .. lastname .. "`",
            "**Character ID:** `" .. charId .. "`",
            "**Shop:** `" .. shopName .. "`",
            "**Action:** `" .. (action == "add" and "Add" or "Remove") .. "`",
            "**Amount:** `" .. amount .. "`",
            "**New Ledger Balance:** `" .. currentLedger .. "`"
        }, "\n")
    }}

    -- Send to shop-specific webhook if available
    if shop.webhook_link then
        BccUtils.Discord.sendMessage(shop.webhook_link,
            Config.WebhookTitle,
            Config.WebhookAvatar,
            "💰 Ledger Modified",
            nil,
            message
        )
    end

    -- Always send to global webhook
    BccUtils.Discord.sendMessage(Config.Webhook,
        Config.WebhookTitle,
        Config.WebhookAvatar,
        "💰 Ledger Modified",
        nil,
        message
    )

    devPrint("Ledger updated successfully. New Balance: " .. currentLedger)
    NotifyClient(src, _U("ledgerUpdated"), "success", 4000)
    cb(true)
end)