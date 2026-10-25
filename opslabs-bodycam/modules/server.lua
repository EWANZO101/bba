-- Shared by the bundled modules (modules/*): the portal connection from ServerConfig.XonSight, and the client-safe
-- part of ServerConfig.Modules handed to players through GlobalState (config_server.lua itself never reaches
-- clients - it holds the webhook key/token).

Modules = {}

local xs = ServerConfig.XonSight or {}
local mods = ServerConfig.Modules or {}

function Modules.SiteUrl()
    return xs.Url or ''
end

-- Token wins over Key, same as server/xonsight.lua
function Modules.Headers()
    local h = { ['Content-Type'] = 'application/json' }
    if xs.Token and xs.Token ~= '' then
        h['X-XonSight-Token'] = xs.Token
    elseif xs.Key and xs.Key ~= '' then
        h['X-XonSight-Key'] = xs.Key
    end
    return h
end

local tablet, phone = mods.Tablet or {}, mods.LbPhone or {}

GlobalState['opslabs-bodycam:modules'] = {
    tablet = tablet.Enabled == true and {
        url = Modules.SiteUrl() ~= '' and (Modules.SiteUrl() .. (tablet.StartPath or '/dashboard')) or '',
        toggleKey = tablet.ToggleKey or 'F6',
        propModel = tablet.PropModel or 'prop_cs_tablet',
        attachBone = tablet.AttachBone or 'PH_L_Hand',
        attachOffset = tablet.AttachOffset or { x = 0.0, y = 0.0, z = 0.0 },
        attachRotation = tablet.AttachRotation or { x = 0.0, y = 0.0, z = 0.0 },
        allowedJobs = tablet.AllowedJobs or {},
        disableAttackWhileOpen = tablet.DisableAttackWhileOpen ~= false,
    } or false,
    lbphone = phone.Enabled == true and {
        siteUrl = Modules.SiteUrl(),
        identifier = phone.Identifier or 'xonsight',
        name = phone.Name or 'Xon Sight',
        description = phone.Description or '',
        developer = phone.Developer or '',
        startPath = phone.StartPath or '/dashboard',
        defaultApp = phone.DefaultApp == true,
        price = phone.Price,
        size = phone.Size or 4096,
        allowCapture = phone.AllowCapture ~= false,
    } or false,
}
