function Notify(message, type, position, transition, icon)
    FeatherMenu:Notify({
        message = message,
        type = type or "info",               -- success, warning, error, default
        hideProgressBar = false,             -- hide the progressbar (true/false)
        transition = transition or "slide",  -- bounce, flip, slide, zoom
        autoClose = 6000,
        position = position or "top-center", --top-left top-center top-right bottom-left bottom-center bottom-right
        style = {},                          --	CSS style overrides
        toastStyle = {},                     -- CSS style overrides
        progressStyle = {},                  -- CSS style overrides
        icon = icon or true                  -- Can copy/paste emoji here. Or set to true for default icons.
    }, function(data)
        --devPrint("[NOTIFY] " .. data.type .. " - Notification ID: " .. tostring(data.id))
    end)
end
BccUtils.RPC:Register("bcc-shops:NotifyClient", function(data)
    Notify(data.message, data.type)
end)