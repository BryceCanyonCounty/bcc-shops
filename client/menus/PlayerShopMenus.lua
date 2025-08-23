local MAX_SELL_PRICE = Config.MAX_SELL_PRICE

function OpenPlayerStoreMenu(shopId, shopName, invLimit, ledger, isOwner, hasAccess)
    devPrint("Opening store menu for shop: " .. shopName)
    devPrint("Is player owner: " .. tostring(isOwner))
    devPrint("player has acces: " .. tostring(hasAccess))
    local isAdmin = IsPlayerAdmin()
    local playerbuySellPage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:buysell:page')
    playerbuySellPage:RegisterElement('header', {
        value = shopName,
        slot = "header"
    })

    playerbuySellPage:RegisterElement('button', {
        label = _U("storeBuyItems"),
        slot = "content"
    }, function()
        OpenBuyMenu(shopName, "player")
    end)

    playerbuySellPage:RegisterElement('button', {
        label = _U("storeSellItems"),
        slot = "content"
    }, function()
        OpenSellMenu(shopName, "player")
    end)

    if isOwner or hasAccess then
        devPrint("Player has full access to shop: " .. shopName)
        devPrint("Player is the owner of the shop: " .. shopName)
        playerbuySellPage:RegisterElement('line', {
            slot = "footer"
        })

        playerbuySellPage:RegisterElement('button', {
            label = _U("manageStore"),
            slot = "footer"
        }, function()
            local playerManagePage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:manage:page')
            playerManagePage:RegisterElement('header', {
                value = shopName,
                slot = "header"
            })
            playerManagePage:RegisterElement('button', {
                label = _U("storeManageItems"),
                slot = "content"
            }, function()
                local managePlayerItems = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerItems:page')
                managePlayerItems:RegisterElement('header', {
                    value = shopName,
                    slot = "header"
                })

                managePlayerItems:RegisterElement('button', {
                    label = _U("storeAddItems"),
                    slot = "content"
                }, function()
                    OpenAddPlayerItemMenu(shopName)
                end)
                managePlayerItems:RegisterElement('button', {
                    label = _U("storeEditItems"),
                    slot = "content"
                }, function()
                    OpenEditItemMenu(shopName, "player")
                end)

                managePlayerItems:RegisterElement('button', {
                    label = _U("storeRemoveItems"),
                    slot = "content"
                }, function()
                    OpenRemovePlayerItemMenu(shopName)
                end)

                managePlayerItems:RegisterElement('line', {
                    slot = "footer"
                })

                managePlayerItems:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    playerManagePage:RouteTo()
                end)

                managePlayerItems:RegisterElement('bottomline', {
                    slot = "footer"
                })

                BCCShopsMainMenu:Open({
                    startupPage = managePlayerItems
                })
            end)

            playerManagePage:RegisterElement('button', {
                label = _U("ledgerButton"),
                slot = "content"
            }, function()
                local managePlayerLedger = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerLedger:page')
                local addAmount, removeAmount = "", ""

                managePlayerLedger:RegisterElement('header', {
                    value = shopName,
                    slot = "header"
                })

                managePlayerLedger:RegisterElement('button', {
                    label = _U("addMoneyToLedger"),
                    slot = "content"
                }, function()
                    local managePlayerLedgerAdd = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerLedgerAdd:page')

                    managePlayerLedgerAdd:RegisterElement('header', {
                        value = shopName,
                        slot = "header"
                    })

                    managePlayerLedgerAdd:RegisterElement('input', {
                        label = _U("amountToAdd"),
                        placeholder = _U("enterAmountToAdd"),
                        slot = "content"
                    }, function(data)
                        addAmount = data.value
                    end)

                    managePlayerLedgerAdd:RegisterElement('line', { slot = "footer" })

                    managePlayerLedgerAdd:RegisterElement('button', {
                        label = _U("confirmAddMoney"),
                        slot = "footer"
                    }, function()
                        local amount = tonumber(addAmount)
                        if amount and amount > 0 then
                            BccUtils.RPC:Call("bcc-shops:ModifyLedger", {
                                shopName = shopName,
                                amount = amount,
                                action = "add"
                            }, function(success)
                                if success then
                                    Notify(_U("moneyAddedToLedger"), "success", 4000)
                                    managePlayerLedger:RouteTo()
                                    addAmount = ""
                                else
                                    Notify(_U("failedToUpdateLedger"), "error", 4000)
                                end
                            end)
                        else
                            Notify(_U("invalidAmountToAdd"), "warning", 4000)
                        end
                    end)

                    managePlayerLedgerAdd:RegisterElement('button', {
                        label = _U('backButton'),
                        slot = "footer"
                    }, function()
                        managePlayerLedger:RouteTo()
                    end)

                    managePlayerLedgerAdd:RegisterElement('bottomline', { slot = "footer" })
                    managePlayerLedgerAdd:RegisterElement('line', { slot = "content" })

                    BCCShopsMainMenu:Open({ startupPage = managePlayerLedgerAdd })
                end)

                managePlayerLedger:RegisterElement('button', {
                    label = _U("removeMoneyFromLedger"),
                    slot = "content"
                }, function()
                    local managePlayerLedgerRemove = BCCShopsMainMenu:RegisterPage(
                        'bcc-shops:managePlayerLedgerRemove:page')

                    managePlayerLedgerRemove:RegisterElement('header', {
                        value = shopName,
                        slot = "header"
                    })

                    managePlayerLedgerRemove:RegisterElement('input', {
                        label = _U("amountToRemove"),
                        placeholder = _U("enterAmountToRemove"),
                        slot = "content"
                    }, function(data)
                        removeAmount = data.value
                    end)

                    managePlayerLedgerRemove:RegisterElement('line', { slot = "footer" })

                    managePlayerLedgerRemove:RegisterElement('button', {
                        label = _U("confirmRemoveMoney"),
                        slot = "footer"
                    }, function()
                        local amount = tonumber(removeAmount)
                        if amount and amount > 0 then
                            BccUtils.RPC:Call("bcc-shops:ModifyLedger", {
                                shopName = shopName,
                                amount = amount,
                                action = "remove"
                            }, function(success)
                                if success then
                                    Notify(_U("moneyRemovedFromLedger"), "success", 4000)
                                    managePlayerLedger:RouteTo()
                                    removeAmount = ""
                                else
                                    Notify(_U("failedToUpdateLedger"), "error", 4000)
                                end
                            end)
                        else
                            Notify(_U("invalidAmountToRemove"), "warning", 4000)
                        end
                    end)

                    managePlayerLedgerRemove:RegisterElement('button', {
                        label = _U('backButton'),
                        slot = "footer"
                    }, function()
                        managePlayerLedger:RouteTo()
                    end)

                    managePlayerLedgerRemove:RegisterElement('bottomline', { slot = "footer" })

                    BCCShopsMainMenu:Open({ startupPage = managePlayerLedgerRemove })
                end)

                managePlayerLedger:RegisterElement('line', { slot = "footer" })

                managePlayerLedger:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    playerManagePage:RouteTo()
                end)

                managePlayerLedger:RegisterElement('bottomline', { slot = "footer" })

                BCCShopsMainMenu:Open({ startupPage = managePlayerLedger })
            end)

            playerManagePage:RegisterElement('button', {
                label = _U("addRemoveAccess"),
                slot = "content"
            }, function()
                local managePlayerAccess = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerLedger:page')

                managePlayerAccess:RegisterElement('header', {
                    value = shopName,
                    slot = "header"
                })

                managePlayerAccess:RegisterElement('button', {
                    label = _U("giveAccess"),
                    slot = "content"
                }, function()
                    devPrint("Opening GiveAccessMenu for shopId: " ..
                        tostring(shopId) .. ", shopName: " .. tostring(shopName))

                    BccUtils.RPC:Call("bcc-shops:FetchOnlinePlayers", {}, function(players)
                        if not players or #players == 0 then
                            Notify(_U("noOnlinePlayersFound"), "warning", 4000)
                            return
                        end

                        local giveAccessPage = BCCShopsMainMenu:RegisterPage('bcc-shops:giveaccess')

                        giveAccessPage:RegisterElement('header', {
                            value = _U("giveAccessTo") .. shopName,
                            slot = "header"
                        })

                        giveAccessPage:RegisterElement('line', { slot = "header" })

                        for _, p in ipairs(players) do
                            local label = p.name
                            giveAccessPage:RegisterElement('button', {
                                label = label,
                                slot = "content"
                            }, function()
                                devPrint("Giving access to charId: " ..
                                    tostring(p.charId) .. " for shopId: " .. tostring(shopId))
                                BccUtils.RPC:Call("bcc-shops:GiveAccess", {
                                    shopId = shopId,
                                    characterId = p.charId
                                }, function(success)
                                    devPrint("Access result: " .. tostring(success))
                                    if success then
                                        Notify(_U("accessGranted"), "success", 4000)
                                        BCCShopsMainMenu:Close()
                                    end
                                end)
                            end)
                        end

                        giveAccessPage:RegisterElement('line', { slot = "footer" })

                        giveAccessPage:RegisterElement('button', {
                            label = _U('backButton'),
                            slot = "footer"
                        }, function()
                            managePlayerAccess:RouteTo()
                        end)

                        giveAccessPage:RegisterElement('bottomline', { slot = "footer" })

                        BCCShopsMainMenu:Open({ startupPage = giveAccessPage })
                    end)
                end)

                managePlayerAccess:RegisterElement('button', {
                    label = _U("removeAccess"),
                    slot = "content"
                }, function()
                    devPrint("[CLIENT] Requesting access list for shop: " .. shopName)

                    BccUtils.RPC:Call("bcc-shops:GetAccessList", { shopName = shopName }, function(results)
                        if not results or #results == 0 then
                            devPrint("[CLIENT] No players with access returned.")
                            Notify(_U("noPlayersWithAccess"), "warning", 4000)
                            return
                        end

                        devPrint("[CLIENT] Access list received with " .. #results .. " entries.")

                        local accessListPage = BCCShopsMainMenu:RegisterPage("accesslist:" .. shopName)

                        accessListPage:RegisterElement("header", {
                            value = _U("playersWithAccessTo") .. shopName,
                            slot = "header"
                        })

                        for _, player in ipairs(results) do
                            local selectedCharacterId = player.character_id
                            devPrint("[CLIENT] Adding button for: " ..
                                player.firstname .. " " .. player.lastname .. " (ID: " .. selectedCharacterId .. ")")

                            accessListPage:RegisterElement("button", {
                                label = player.firstname ..
                                    " " .. player.lastname .. " (ID: " .. selectedCharacterId .. ")",
                                slot = "content"
                            }, function()
                                devPrint("[CLIENT] Selected character for removal: " .. selectedCharacterId)

                                local removeAccessPage = BCCShopsMainMenu:RegisterPage('bcc-shops:removeaccess')

                                removeAccessPage:RegisterElement('header', {
                                    value = _U("removeAccessFrom") .. shopName,
                                    slot = "header"
                                })

                                removeAccessPage:RegisterElement('button', {
                                    label = _U("yes"),
                                    slot = "footer"
                                }, function()
                                    devPrint("[CLIENT] Confirming removal. Fetching shop info for: " .. shopName)

                                    BccUtils.RPC:Call("bcc-shops:fetchPlayerStoreInfo", { shopName = shopName },
                                        function(shop)
                                            if shop then
                                                devPrint("[CLIENT] Shop info found: ID = " ..
                                                    tostring(shop.shopId) ..
                                                    ". Sending removal request for character ID: " .. selectedCharacterId)

                                                BccUtils.RPC:Call("bcc-shops:RemoveAccess", {
                                                    shopId = shop.shopId,
                                                    characterId = selectedCharacterId
                                                }, function(success)
                                                    if success then
                                                        Notify(_U("accessRemovedSuccessfully"), "success", 4000)
                                                        managePlayerAccess:RouteTo()
                                                    else
                                                        Notify(_U("failedToRemoveAccess"), "error", 4000)
                                                    end
                                                end)
                                            else
                                                Notify("Shop not found.", "warning", 4000)
                                            end
                                        end)
                                end)

                                removeAccessPage:RegisterElement('button', {
                                    label = _U("no"),
                                    slot = "footer"
                                }, function()
                                    managePlayerAccess:RouteTo()
                                end)

                                removeAccessPage:RegisterElement('button', {
                                    label = _U('backButton'),
                                    slot = "footer"
                                }, function()
                                    OpenStoreMenu(globalNearbyShops)
                                end)

                                BCCShopsMainMenu:Open({ startupPage = removeAccessPage })
                            end)
                        end

                        accessListPage:RegisterElement("button", {
                            label = _U('backButton'),
                            slot = "footer"
                        }, function()
                            OpenStoreMenu(globalNearbyShops)
                        end)

                        BCCShopsMainMenu:Open({ startupPage = accessListPage })
                    end)
                end)

                managePlayerAccess:RegisterElement('line', { slot = "footer" })

                managePlayerAccess:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    playerManagePage:RouteTo()
                end)

                managePlayerAccess:RegisterElement('bottomline', { slot = "footer" })

                BCCShopsMainMenu:Open({ startupPage = managePlayerAccess })
            end)

            playerManagePage:RegisterElement('button', {
                label = _U("webhook"),
                slot = "content"
            }, function()
                local managePlayerWebhook = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerWebhook:page')

                managePlayerWebhook:RegisterElement('header', {
                    value = shopName,
                    slot = "header"
                })

                local webhookValue = ""

                managePlayerWebhook:RegisterElement('input', {
                    label = _U("enterDiscordWebhookURL"),
                    placeholder = "https://discord.com/api/webhooks/...",
                    type = "text",
                    default = "",
                    slot = "content"
                }, function(input)
                    webhookValue = input.value
                end)

                managePlayerWebhook:RegisterElement('button', {
                    label = _U("submitWebhook"),
                    slot = "content"
                }, function()
                    if not webhookValue or webhookValue == "" then
                        Notify(_U("invalidWebhookURL"), "error", 4000)
                        return
                    end

                    BccUtils.RPC:Call("bcc-shops:SetWebhook", {
                        shopId = shopId,
                        webhook = webhookValue
                    }, function(success)
                        if success then
                            BCCShopsMainMenu:Close()
                            Notify(_U("webhookUpdated"), "success", 4000)
                        else
                            Notify(_U("failedToUpdateWebhook"), "error", 4000)
                        end
                    end)
                end)

                managePlayerWebhook:RegisterElement('line', {
                    slot = "footer"
                })

                managePlayerWebhook:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    playerManagePage:RouteTo()
                end)

                managePlayerWebhook:RegisterElement('bottomline', { slot = "footer" })

                BCCShopsMainMenu:Open({ startupPage = managePlayerWebhook })
            end)

            playerManagePage:RegisterElement('button', {
                label = _U("manageBlip"),
                slot = "content"
            }, function()
                local managePlayerBlip = BCCShopsMainMenu:RegisterPage('bcc-shops:managePlayerBlip:page')

                managePlayerBlip:RegisterElement('header', {
                    value = shopName,
                    slot = "header"
                })

                managePlayerBlip:RegisterElement('button', {
                    label = _U("enableBlip"),
                    slot = "content"
                }, function()
                    local enableShopBlip = BCCShopsMainMenu:RegisterPage('bcc-shops:enableShopBlip:page')

                    enableShopBlip:RegisterElement('header', {
                        value = shopName,
                        slot = "header"
                    })

                    enableShopBlip:RegisterElement('button', {
                        label = _U("showBlip"),
                        slot = "content"
                    }, function()
                        BccUtils.RPC:Call("bcc-shops:SetShopBlipEnabled", {
                            shopName = shopName,
                            enabled = true
                        }, function(success)
                            if success then
                                Notify(_U("blipEnabled"), "success", 4000)

                                for i, blipObj in ipairs(CreatedBlip) do
                                    if blipObj.name == shopName then
                                        blipObj:Remove()
                                        table.remove(CreatedBlip, i)
                                        break
                                    end
                                end

                                local shop = GetShopByName(shopName)
                                if shop then
                                    local hash = tonumber(shop.blip_hash) or 1475879922
                                    local newBlip = BccUtils.Blips:SetBlip(shop.shop_name, hash, 1, shop.pos_x, shop.pos_y, shop.pos_z)
                                    newBlip.name = shop.shop_name
                                    table.insert(CreatedBlip, newBlip)
                                end
                            else
                                Notify(_U('failedToEnableBlip'), 'error', 4000)
                            end
                        end)
                    end)
                    
                    enableShopBlip:RegisterElement('button', {
                        label = _U('hideBlip'),
                        slot = "content"
                    }, function()
                        BccUtils.RPC:Call("bcc-shops:SetShopBlipEnabled", {
                            shopName = shopName,
                            enabled = false
                        }, function(success)
                            if success then
                                Notify(_U('blipDisabled'), "warning", 4000)

                                -- Remove blip
                                for i, blipObj in ipairs(CreatedBlip) do
                                    if blipObj.name == shopName then
                                        blipObj:Remove()
                                        table.remove(CreatedBlip, i)
                                        break
                                    end
                                end
                            else
                                Notify(_U("failedToDisableBlip"), "error", 4000)
                            end
                        end)
                    end)

                    enableShopBlip:RegisterElement('line', { slot = "footer" })

                    enableShopBlip:RegisterElement('button', {
                        label = _U('backButton'),
                        slot = "footer"
                    }, function()
                        managePlayerBlip:RouteTo()
                    end)

                    enableShopBlip:RegisterElement('bottomline', { slot = "footer" })

                    BCCShopsMainMenu:Open({ startupPage = enableShopBlip })
                end)


                managePlayerBlip:RegisterElement('button', {
                    label = _U('changeBlip'),
                    slot = "content"
                }, function()
                    local changeShopBlip = BCCShopsMainMenu:RegisterPage('bcc-shops:changeShopBlip:page')

                    changeShopBlip:RegisterElement('header', {
                        value = shopName,
                        slot = "header"
                    })

                    for _, blip in ipairs(Config.BlipStyles) do
                        local imgPath = 'nui://bcc-shops/images/' .. blip.blipName .. '.png'

                        local html = string.format([[
                            <div style="display: flex; align-items: center; padding: 5px;">
                                <img src="%s" style="height: 40px; width: 40px; margin-right: 12px;">
                                <div style="font-size: 1.0vw; font-weight: bold;">%s</div>
                            </div>
                        ]], imgPath, blip.label)

                        changeShopBlip:RegisterElement('button', {
                            html = html,
                            slot = "content"
                        }, function()
                            selectedBlipHash = blip.blipHash
                            devPrint("Selected Blip: " .. blip.label)

                            BccUtils.RPC:Call("bcc-shops:SetPlayerShopBlip", {
                                shopName = shopName,
                                blipHash = selectedBlipHash
                            }, function(success)
                                if success then
                                    Notify(_U("blipUpdated"), "success", 4000)

                                    -- 🔄 Remove old blip for this shop
                                    for i, blipObj in ipairs(CreatedBlip) do
                                        if blipObj.name == shopName then
                                            blipObj:Remove()
                                            table.remove(CreatedBlip, i)
                                            break
                                        end
                                    end

                                    -- 🔁 Add new blip with updated hash
                                    local shop = GetShopByName(shopName) -- Make sure this exists
                                    if shop then
                                        local newBlip = BccUtils.Blips:SetBlip(shop.shop_name, selectedBlipHash, 1,
                                            shop.pos_x, shop.pos_y, shop.pos_z)
                                        newBlip.name = shop.shop_name
                                        table.insert(CreatedBlip, newBlip)
                                    end
                                    managePlayerBlip:RouteTo()
                                else
                                    Notify(_U("blipUpdateFailed"), "error", 4000)
                                end
                            end)
                        end)
                    end

                    changeShopBlip:RegisterElement('line', {
                        slot = "footer"
                    })

                    changeShopBlip:RegisterElement('button', {
                        label = _U('backButton'),
                        slot = "footer"
                    }, function()
                        managePlayerBlip:RouteTo()
                    end)

                    changeShopBlip:RegisterElement('bottomline', {
                        slot = "footer"
                    })

                    BCCShopsMainMenu:Open({
                        startupPage = changeShopBlip
                    })
                end)

                managePlayerBlip:RegisterElement('button', {
                    label = _U('backButton'),
                    slot = "footer"
                }, function()
                    playerbuySellPage:RouteTo()
                end)

                BCCShopsMainMenu:Open({
                    startupPage = managePlayerBlip
                })
            end)

            playerManagePage:RegisterElement('line', {
                slot = "footer"
            })

            playerManagePage:RegisterElement('button', {
                label = _U('backButton'),
                slot = "footer"
            }, function()
                playerbuySellPage:RouteTo()
            end)

            playerManagePage:RegisterElement('bottomline', {
                slot = "footer"
            })

            BCCShopsMainMenu:Open({
                startupPage = playerManagePage
            })
        end)

        playerbuySellPage:RegisterElement('bottomline', {
            slot = "footer"
        })
        playerbuySellPage:RegisterElement('textdisplay', {
            value = _U('inventoryLimit') .. invLimit,
            slot = "footer"
        })
        playerbuySellPage:RegisterElement('textdisplay', {
            value = _U('ledger') .. ledger,
            slot = "footer"
        })
        playerbuySellPage:RegisterElement('line', {
            slot = "footer"
        })
    end

    --[[if isAdmin and not isOwner then
        devPrint(_U('playerIsAdmin') .. shopName)

        playerbuySellPage:RegisterElement('button', {
            label = _U('addItemsAdmin'),
            slot = "content"
        }, function()
            OpenAddPlayerItemMenu(shopName)
        end)

        playerbuySellPage:RegisterElement('button', {
            label = _U('editItemsAdmin'),
            slot = "content"
        }, function()
            OpenEditItemMenu(shopName, "player")
        end)

        playerbuySellPage:RegisterElement('button', {
            label = _U('removeItemsAdmin'),
            slot = "content"
        }, function()
            OpenRemovePlayerItemMenu(shopName)
        end)
    end]] --

    BCCShopsMainMenu:Open({
        startupPage = playerbuySellPage
    })
end

function OpenCreatePlayerStoreMenu(players, storeDetails)
    storeDetails = storeDetails or {
        shopName = '',
        invLimit = 0,
        ownerId = storeDetails and storeDetails.ownerId or '',
        pos_x = nil,
        pos_y = nil,
        pos_z = nil,
        storeHeading = nil
    }

    local createPlayerStorePage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:createstore')
    createPlayerStorePage:RegisterElement('header', {
        value = _U('createPlayerStore'),
        slot = "header"
    })
    local shopName = ''

    createPlayerStorePage:RegisterElement('input', {
        label = _U('storeName'),
        slot = "content",
        type = "text",
        placeholder = _U('enterStoreName')
    }, function(data)
        shopName = data.value
    end)

    createPlayerStorePage:RegisterElement('input', {
        label = _U('invLimit'),
        slot = "content",
        type = "number",
        placeholder = _U('enterInvLimit'),
        value = storeDetails.invLimit
    }, function(data)
        storeDetails.invLimit = tonumber(data.value)
    end)

    createPlayerStorePage:RegisterElement('button', {
        label = _U('setCoordinates'),
        slot = "content"
    }, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        storeDetails.pos_x = coords.x
        storeDetails.pos_y = coords.y
        storeDetails.pos_z = coords.z
        storeDetails.storeHeading = heading

        Notify(_U('coordinatesSet') .. tostring(coords) .. " | H: " .. math.floor(heading), "info", 4000)
        devPrint("Coordinates & Heading set: " .. tostring(coords) .. " Heading: " .. heading)
    end)

    createPlayerStorePage:RegisterElement('button', {
        label = _U('create'),
        slot = "footer"
    }, function()
        if shopName ~= '' and storeDetails.ownerId ~= '' then
            storeDetails.shopName = shopName
            if storeDetails.pos_x and storeDetails.pos_y and storeDetails.pos_z then
                devPrint("Creating store with details: " .. json.encode(storeDetails))
                BccUtils.RPC:Call("bcc-shops:createplayershop", storeDetails, function(success)
                    if success then
                        BCCShopsMainMenu:Close()
                        Notify(_U('shopCreatedSuccess'), "success", 4000)
                    else
                        Notify(_U('shopCreatedFail'), "error", 4000)
                    end
                end)
            else
                Notify(_U('pleaseSetLocation'), "warning", 4000)
                devPrint("Location not set")
            end
        else
            Notify(_U('provideAllStoreDetails'), "warning", 4000)
            devPrint("Store details incomplete: shopName=" .. shopName .. ", ownerId=" .. storeDetails.ownerId)
        end
    end)

    createPlayerStorePage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenCreateStoreMenu(players)
    end)

    BCCShopsMainMenu:Open({
        startupPage = createPlayerStorePage
    })
end

function SelectOwner(players)
    if not players or #players == 0 then
        devPrint("No players available for selection.")
        return
    end

    local playerListPage = BCCShopsMainMenu:RegisterPage('bcc-shops:selectowner')
    playerListPage:RegisterElement('header', {
        value = _U('selectStoreOwner'),
        slot = "header"
    })

    for _, player in ipairs(players) do
        playerListPage:RegisterElement('button', { label = player.name, slot = "content" }, function()
            local ownerId = player.id
            Notify("Owner selected: " .. player.name, "success", 4000)
            devPrint("Owner selected: " .. player.name .. ", ID: " .. ownerId)
            OpenCreatePlayerStoreMenu(players, { ownerId = ownerId })
        end)
    end

    playerListPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    playerListPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenCreateStoreMenu(players)
    end)

    playerListPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({ startupPage = playerListPage })
end

function OpenAddPlayerItemDetailMenu(shopName, item)
    local addItemMenu = BCCShopsMainMenu:RegisterPage('bcc-shops:player:addItemDetail')
    addItemMenu:RegisterElement('header', {
        value = item.label,
        slot = "header"
    })
    addItemMenu:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    addItemMenu:RegisterElement('button', {
        label = _U('addToBuyInventory'),
        slot = "content"
    }, function()
        OpenAddPlayerItemDetailMenuWithDetails(shopName, item, 'buy')
    end)

    addItemMenu:RegisterElement('button', {
        label = _U('addToSellInventory'),
        slot = "content"
    }, function()
        OpenAddPlayerItemDetailMenuWithDetails(shopName, item, 'sell')
    end)

    addItemMenu:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenAddPlayerItemMenu(shopName)
    end)

    addItemMenu:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({
        startupPage = addItemMenu
    })
end

function OpenPlayerInventoryMenu(shopName, inventory, weapons)
    devPrint("Opening inventory menu for shop: " .. shopName)

    local addItemPage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:additems')
    addItemPage:RegisterElement('header', { value = _U('inventory'), slot = "header" })
    addItemPage:RegisterElement('line', { slot = "header", style = {} })

    -- Combine inventory items
    for _, item in ipairs(inventory or {}) do
        local itemName = item.item_name or "unknown_item"
        local label = item.label or _U('unknown')
        local count = item.count or 0
        local imgPath = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png'

        local html = string.format([[
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 5px;">
                <img src="%s" style="height: 40px; width: 40px; margin-right: 10px;">
                <span style="flex-grow: 1; text-align: center; font-size: 1.0vw;">%s</span>
                <span style="font-size: 0.9vw; opacity: 0.7;">x%s</span>
            </div>
        ]], imgPath, label, count)

        addItemPage:RegisterElement('button', {
            html = html,
            slot = "content"
        }, function()
            devPrint("Clicked inventory item: " .. label)
            OpenAddPlayerItemDetailMenu(shopName, item)
        end)
    end

    -- Add weapons
    for _, weapon in ipairs(weapons or {}) do
        local itemName = weapon.name or "unknown_weapon"
        local label = weapon.custom_label or weapon.label or _U('unknown')
        local serial = weapon.serial_number or "N/A"
        local imgPath = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png'

        local html = string.format([[
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 5px;">
                <img src="%s" style="height: 40px; width: 40px; margin-right: 10px;">
                <span style="flex-grow: 1; text-align: center; font-size: 1.0vw;">%s</span>
                <span style="font-size: 0.7vw; opacity: 0.5;">🔫 Serial: %s</span>
            </div>
        ]], imgPath, label, serial)

        weapon.is_weapon = 1 ---set to 1 aka true
        weapon.item_name = itemName

        addItemPage:RegisterElement('button', {
            html = html,
            slot = "content"
        }, function()
            devPrint("Clicked weapon: " .. label .. " [" .. serial .. "]")
            OpenAddPlayerItemDetailMenu(shopName, weapon)
        end)
    end

    addItemPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    addItemPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        devPrint("Back button clicked, returning to store menu")
        OpenPlayerBuySellMenu(shopName)
    end)

    addItemPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({
        startupPage = addItemPage
    })
end

function OpenAddPlayerItemDetailMenuWithDetails(shopName, item, actionType)
    devPrint("Opening item detail menu for item: " .. (item.label or "Unknown Item") .. ", Action: " .. actionType)

    local categories = BccUtils.RPC:CallAsync("bcc-shops:GetShopCategories")
    local categoryOptions = {}

    if categories and #categories > 0 then
        for _, cat in ipairs(categories) do
            table.insert(categoryOptions, { text = cat.text or cat.label or "unknown", value = tostring(cat.value) })
        end
    else
        Notify("No categories found in database!", "error", 4000)
        return
    end

    local itemDetailPage     = BCCShopsMainMenu:RegisterPage('bcc-shops:player:itemdetails')

    local itemName           = item.item_name or "unknown_item"
    local itemLabel          = item.label or _U("unknownItem")
    local inputPrice         = (actionType == 'buy' and item.buy_price or item.sell_price) or 0
    local inputQuantity      = 1
    local selectedCategoryId = tostring(item.category_id or "") -- default selection

    itemDetailPage:RegisterElement('header', {
        value = itemLabel,
        slot = "header"
    })
    itemDetailPage:RegisterElement('line', {
        slot = "header"
    })

    itemDetailPage:RegisterElement('input', {
        label = (actionType == 'buy' and _U('buyPrice') or _U('sellPrice')),
        slot = "content",
        type = "number",
        default = inputPrice,
        min = 0
    }, function(data)
        inputPrice = tonumber(data.value) or inputPrice
        devPrint("Updated Price: " .. inputPrice)
    end)

    itemDetailPage:RegisterElement('input', {
        label = _U('storeQty'),
        slot = "content",
        type = "number",
        default = inputQuantity,
        min = 1
    }, function(data)
        inputQuantity = tonumber(data.value) or 1
        devPrint("Updated Quantity: " .. inputQuantity)
    end)

    itemDetailPage:RegisterElement('dropdown', {
        label = _U('category'),
        slot = "content",
        options = categoryOptions,
        default = selectedCategoryId
    }, function(data)
        selectedCategoryId = data.value
        devPrint("Selected category_id: " .. selectedCategoryId)
    end)

    itemDetailPage:RegisterElement('button', {
        label = _U('submit'),
        slot = "footer"
    }, function()
        if inputQuantity <= 0 then
            devPrint("Invalid quantity: " .. inputQuantity)
            Notify(_U('invalidQuantity'), "error", 4000)
            return
        end
        if inputPrice > MAX_SELL_PRICE then
            devPrint("Entered price exceeds maximum limit: " .. inputPrice)
            Notify(_U('price_limit_exceeded'), "error", 4000)
            return
        end
        -- Weapon-specific handling
        if item.is_weapon == 1 then
            local weaponPayload = {
                shopName      = shopName,
                weaponName    = itemName,
                weaponLabel   = itemLabel,
                buyPrice      = inputPrice,
                sellPrice     = 0,
                currencyType  = "cash",
                category      = tonumber(selectedCategoryId),
                levelRequired = 0,
                customDesc    = item.description or "N/A",
                weaponInfo    = item.weapon_info or "{}",
                weaponId      = item.weapon_id or item.id,
                quantity      = 1,
            }

            devPrint("Sending weapon to shop: " .. json.encode(weaponPayload))
            BccUtils.RPC:Call("bcc-shops:AddWeaponItem", weaponPayload, function(success, msg)
                if success then
                    Notify(_U("weaponAddedSuccess"), "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(msg or _U("weaponAddedFail"), "error", 4000)
                end
            end)
            return
        end

        -- Regular item handling
        local payload = {
            shopName    = shopName,
            itemLabel   = itemLabel,
            itemName    = itemName,
            quantity    = inputQuantity,
            category_id = tonumber(selectedCategoryId)
        }

        if actionType == 'buy' then
            payload.buyPrice = inputPrice
            devPrint("Adding buy item: " .. json.encode(payload))
            BccUtils.RPC:Call("bcc-shops:AddBuyItem", payload, function(success)
                if success then
                    Notify(_U("buyItemAdded"), "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(_U("buyItemAddFail"), "error", 4000)
                end
            end)
        else
            payload.sellPrice = inputPrice
            devPrint("Adding sell item: " .. json.encode(payload))
            BccUtils.RPC:Call("bcc-shops:AddSellItem", payload, function(success)
                if success then
                    Notify(_U("sellItemAdded"), "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(_U("sellItemAddFail"), "error", 4000)
                end
            end)
        end
    end)

    itemDetailPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenAddPlayerItemDetailMenu(shopName, item)
    end)

    BCCShopsMainMenu:Open({ startupPage = itemDetailPage })
end

function OpenRemovePlayerItemMenu(shopName)
    devPrint("Fetching shop items for: " .. shopName)

    local result = BccUtils.RPC:CallAsync("bcc-shops:FetchShopItems", { shopName = shopName })
    if not result or (not result.items and not result.weapons) then
        Notify(_U("failedToFetchShopItems"), "error", 4000)
        return
    end

    local items = result.items or {}
    local weapons = result.weapons or {}

    local categoryList = {}
    local categoryTypeMap = {}
    local categoryLabelMap = {}

    for cat, entries in pairs(items) do
        table.insert(categoryList, cat)
        categoryTypeMap[cat] = "item"
        categoryLabelMap[cat] = entries._label or cat
    end

    for cat, entries in pairs(weapons) do
        table.insert(categoryList, cat)
        categoryTypeMap[cat] = "weapon"
        categoryLabelMap[cat] = entries._label or cat
    end

    if #categoryList == 0 then
        Notify(_U("noItemsAvailable"), "warning", 4000)
        return
    end

    table.sort(categoryList)
    local currentPage = 1
    local totalPages = #categoryList

    local function renderPage()
        local category = categoryList[currentPage]
        local type = categoryTypeMap[category]
        local entries = (type == "item") and items[category] or weapons[category]
        local categoryLabel = categoryLabelMap[category] or category

        local removeItemPage = BCCShopsMainMenu:RegisterPage("bcc-shops:removeplayeritem:" .. category)
        removeItemPage:RegisterElement("header", {
            value = _U("removeItemFrom") .. shopName,
            slot = "header"
        })
        removeItemPage:RegisterElement("line", { slot = "header", style = {} })

        removeItemPage:RegisterElement("subheader", {
            value = (type == "weapon" and "🔫 " or "🔹 ") .. categoryLabel,
            style = {
                fontSize = "20px",
                bold = true,
                marginBottom = "5px",
                textAlign = "center"
            },
            slot = "content"
        })

        for _, entry in ipairs(entries) do
            local itemName = entry.name or entry.item_name or entry.weapon_name or "unknown_item"
            local label = entry.label or entry.item_label or entry.weapon_label or _U("unknownItem")
            local imgPath = "nui://vorp_inventory/html/img/items/" .. itemName .. ".png"
            local icon = type == "weapon" and '<span style="font-size: 0.7vw; opacity: 0.5;">🔫</span>' or ""

            local html = string.format([[
                <div style="display: flex; align-items: center; padding: 5px;">
                    <img src="%s" style="height: 40px; width: 40px; margin-right: 10px;">
                    <span style="flex-grow: 1; text-align: center; font-size: 1.0vw;">%s</span>
                    %s
                </div>
            ]], imgPath, label, icon)

            removeItemPage:RegisterElement("button", {
                html = html,
                slot = "content"
            }, function()
                RequestRemoveQuantity(shopName, itemName, entry.buy_quantity, entry.sell_quantity, entry.price, entry.sell_price, type == "weapon")
            end)
        end

        removeItemPage:RegisterElement("pagearrows", {
            slot = "footer",
            total = totalPages,
            current = currentPage,
            style = {}
        }, function(data)
            if data.value == "forward" then
                currentPage = math.min(currentPage + 1, totalPages)
            elseif data.value == "back" then
                currentPage = math.max(currentPage - 1, 1)
            end
            renderPage()
        end)

        removeItemPage:RegisterElement("line", { slot = "footer", style = {} })
        removeItemPage:RegisterElement("button", {
            label = _U("backButton"),
            slot = "footer"
        }, function()
            OpenPlayerBuySellMenu(shopName)
        end)
        removeItemPage:RegisterElement("bottomline", { slot = "footer", style = {} })

        BCCShopsMainMenu:Open({ startupPage = removeItemPage })
    end

    renderPage()
end

function RequestRemoveQuantity(shopName, itemName, maxBuyQuantity, maxSellQuantity, buyPrice, sellPrice)
    local inputPage = BCCShopsMainMenu:RegisterPage('bcc-shops:remove:quantity')
    local quantity = 1
    local imgPath = 'nui://vorp_inventory/html/img/items/' .. itemName .. '.png'

    local html =
        '<div style="padding: 10px; font-size: 0.95vw;">' ..
        '<b style="font-size: 1.05vw;">' .. itemName .. '</b><br><br>' ..
        _U('buyStock') .. '<b>' .. maxBuyQuantity .. '</b><br>' ..
        _U('buyPrice') .. '<b>$' .. buyPrice .. '</b><br><br>' ..
        _U('sellStock') .. '<b>' .. maxSellQuantity .. '</b><br>' ..
        _U('sellPrice') .. '<b>$' .. sellPrice .. '</b>' ..
        '</div>'

    inputPage:RegisterElement('header', {
        value = _U('enterQtyToRemove'),
        slot = "header"
    })
    inputPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })
    inputPage:RegisterElement('html', {
        value = html,
        slot = "content"
    })
    inputPage:RegisterElement('line', {
        slot = "content",
        style = {}
    })
    inputPage:RegisterElement('input', {
        label = _U('storeQty'),
        slot = "content",
        type = "number",
        default = 1,
        min = 1
    }, function(data)
        local inputQty = tonumber(data.value)
        if inputQty and inputQty > 0 then
            quantity = inputQty
        else
            Notify(_U("invalidQuantityInput"), "error", 4000)
        end
    end)

    inputPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    inputPage:RegisterElement('button', {
        label = _U("removeForBuy"),
        slot = "footer"
    }, function()
        if quantity <= maxBuyQuantity then
            BccUtils.RPC:Call("bcc-shops:RemoveShopItem", {
                shopName = shopName,
                itemName = itemName,
                quantity = quantity,
                isBuy = true
            }, function(success)
                if success then
                    Notify(_U("itemRemovedSuccessfully"), "success", 4000)
                else
                    Notify(_U("failedToRemoveItem") .. (_U("unknownError")), "error", 4000)
                end
                OpenRemovePlayerItemMenu(shopName)
            end)
            BCCShopsMainMenu:Close()
        else
            Notify(_U("quantityExceedsBuyStock"), "error", 4000)
        end
    end)

    inputPage:RegisterElement('button', {
        label = _U("removeForSell"),
        slot = "footer"
    }, function()
        if quantity <= maxSellQuantity then
            BccUtils.RPC:Call("bcc-shops:RemoveShopItem", {
                shopName = shopName,
                itemName = itemName,
                quantity = quantity,
                isBuy = false
            }, function(success)
                if success then
                    Notify(_U("itemRemovedSuccessfully"), "success", 4000)
                else
                    Notify(_U("failedToRemoveItem") .. (_U("unknownError")), "error")
                end
                OpenRemovePlayerItemMenu(shopName)
            end)
            BCCShopsMainMenu:Close()
        else
            Notify(_U("quantityExceedsSellStock"), "error")
        end
    end)

    inputPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenRemovePlayerItemMenu(shopName)
    end)

    inputPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })
    BCCShopsMainMenu:Open({
        startupPage = inputPage
    })
end

function OpenAddItemMenu(shopName, item, inventoryType)
    local addItemPage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:additem')
    addItemPage:RegisterElement('header', {
        value = _U('addItemTitle') .. item.label,
        slot = "header"
    })
    addItemPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    local quantity = 0
    addItemPage:RegisterElement('input', {
        label = _U('storeQty'),
        slot = "content",
        type = "number",
        placeholder = _U('enterQuantity')
    }, function(data)
        quantity = tonumber(data.value)
    end)

    local price = 0
    addItemPage:RegisterElement('input', {
        label = _U('price'),
        slot = "content",
        type = "number",
        placeholder = _U('enterPrice')
    }, function(data)
        price = tonumber(data.value)
    end)

    addItemPage:RegisterElement('button', {
        label = _U('addItem'),
        slot = "footer"
    }, function()
        if inventoryType == "buy" then
            devPrint("Triggering addBuyItem with itemName: " .. tostring(item.item_name))
            BccUtils.RPC:Call("bcc-shops:AddBuyItem", {
                shopName = shopName,
                itemLabel = item.label,
                itemName = item.item_name,
                quantity = quantity,
                buyPrice = price,
                category = item.category,
                --levelRequired = item.category
            }, function(success)
                if success then
                    devPrint("Item successfully added")
                    BCCShopsMainMenu:Close()
                else
                    devPrint("Failed to add item")
                end
            end)
        else
            devPrint("Triggering addSellItem with itemName: " .. tostring(item.item_name))
            BccUtils.RPC:Call("bcc-shops:AddSellItem", {
                shopName = shopName,
                itemLabel = item.label,
                itemName = item.item_name,
                quantity = quantity,
                sellPrice = price,
                category = item.category,
                levelRequired = item.level_required
            }, function(success)
                if success then
                    Notify(_U("sellItemAddedToStore"), "success", 4000)
                    BCCShopsMainMenu:Close()
                else
                    Notify(_U("failedToAddSellItem"), "error", 4000)
                end
            end)
        end
        BCCShopsMainMenu:Close()
    end)

    addItemPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenAddPlayerItemDetailMenu(shopName, item)
    end)

    BCCShopsMainMenu:Open({
        startupPage = addItemPage
    })
end

function OpenAddItemSelectionMenu(storeName)
    local addItemPage = BCCShopsMainMenu:RegisterPage('bcc-shops:player:additemsmenu')
    addItemPage:RegisterElement('header', {
        value = _U('addItemsTo') .. storeName,
        slot = "header"
    })
    addItemPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    addItemPage:RegisterElement('button', {
        label = _U('addItemsToBuy'),
        slot = "content"
    }, function()
        OpenAddPlayerItemDetailMenu(storeName, "buy")
    end)

    addItemPage:RegisterElement('button', {
        label = _U('addItemsToSell'),
        slot = "content"
    }, function()
        OpenAddPlayerItemDetailMenu(storeName, "sell")
    end)

    addItemPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    addItemPage:RegisterElement('button', {
        label = _U('backButton'),
        slot = "footer"
    }, function()
        OpenBuyMenu(storeName, "player")
    end)

    addItemPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCShopsMainMenu:Open({
        startupPage = addItemPage
    })
end
