VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
discord = BccUtils.Discord.setup(Config.Webhook, Config.WebhookTitle, Config.WebhookAvatar)


BccUtils.RPC:Register("bcc-shops:GetPlayerLevel", function(_, cb, src)
    local user = VORPcore.getUser(src)
    local character = user and user.getUsedCharacter

    if character and character.xp then
        local level = getLevelFromXP(character.xp)
        devPrint("[RPC] Player level for src " .. src .. " is: " .. level)
        cb(level)
    else
        devPrint("[RPC] Character or XP not found for src: " .. src)
        cb(nil)
    end
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-shops')
