-- LB Phone module (was xonsight-lbphone): registers Xon Sight as a custom LB Phone app via the exported
-- AddCustomApp API (https://docs.lbscripts.com/phone/custom-apps/). Settings: config_server.lua →
-- ServerConfig.Modules.LbPhone. The app UI is html/lbphone/.

local RES = GetCurrentResourceName()
local cfg

local function addApp()
    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = cfg.identifier,

        name = cfg.name,
        description = cfg.description,
        developer = cfg.developer,

        defaultApp = cfg.defaultApp,
        size = cfg.size,
        price = cfg.price,

        ui = RES .. "/html/lbphone/index.html",
        icon = "https://cfx-nui-" .. RES .. "/html/lbphone/assets/icon.svg",

        fixBlur = true, -- the UI uses rem/em units, not just px
    })

    if not added then
        print("[opslabs-bodycam:lbphone] Could not add app:", errorMessage)
    end
end

CreateThread(function()
    cfg = ModuleConfig('lbphone')
    if not cfg then return end

    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end
    addApp()
end)

-- lb-phone forgets custom apps added by other resources when it restarts
-- on its own (e.g. during development) - re-register when that happens.
AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" and cfg then
        addApp()
    end
end)

-- The UI asks for this instead of hardcoding the site URL into its script.js.
RegisterNUICallback("xonsight:getConfig", function(_, cb)
    if not cfg then return cb({}) end
    cb({
        siteUrl = cfg.siteUrl,
        startPath = cfg.startPath,
        allowCapture = cfg.allowCapture,
    })
end)

-- The actual webhook POST happens in modules/lbphone/server.lua (keeps the key out of NUI-reachable code) -
-- this relays the captured media URL there and acks the UI right away.
RegisterNUICallback("xonsight:submitEvidence", function(data, cb)
    TriggerServerEvent("opslabs-bodycam:lbphone:submitEvidence", data)
    cb({ ok = true })
end)

RegisterNetEvent("opslabs-bodycam:lbphone:submitResult", function(ok, message)
    local msg = { action = "submitResult", ok = ok, message = message }
    -- the app runs inside lb-phone's frame, not this resource's ui_page
    if not pcall(function() exports["lb-phone"]:SendCustomAppMessage(cfg.identifier, msg) end) then
        SendNUIMessage(msg)
    end
end)
