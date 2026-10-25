-- Lets the LB Phone app submit evidence straight from LB Phone's own camera, independent of the bodycam
-- recording - Xon Sight's webhook contract is generic (POST /evidence with id/submitterIdentifier/
-- submitterName/caption/videoUrl). Runs server-side so the webhook key never lives in client code.

local cfg = (ServerConfig.Modules or {}).LbPhone or {}

local function log(...)
    print("[opslabs-bodycam:lbphone]", ...)
end

if cfg.Enabled ~= true then return end

RegisterNetEvent("opslabs-bodycam:lbphone:submitEvidence", function(data)
    local src = source

    if cfg.AllowCapture == false then
        return
    end

    local siteUrl = Modules.SiteUrl()
    if siteUrl == "" then
        log("ServerConfig.XonSight.Url isn't configured (config_server.lua) - dropping evidence submission from player", src)
        TriggerClientEvent("opslabs-bodycam:lbphone:submitResult", src, false, "Xon Sight isn't configured on this server")
        return
    end

    if not data or not data.videoUrl or data.videoUrl == "" then
        log("Dropped evidence submission from player", src, "- no videoUrl")
        TriggerClientEvent("opslabs-bodycam:lbphone:submitResult", src, false, "No media was captured")
        return
    end

    local playerName = GetPlayerName(src) or ("Player " .. src)
    local identifier = GetPlayerIdentifierByType(src, "license") or ("source:" .. src)

    -- Xon Sight's `id` is "integer, unique per item - re-posting the same id updates it in place". No shared
    -- counter here, so a timestamp plus the player's server id - enough to avoid collisions between captures.
    local evidenceId = math.floor(os.time() * 1000 + src)

    local payload = json.encode({
        id = evidenceId,
        submitterIdentifier = identifier,
        submitterName = playerName,
        caption = (data.caption and data.caption ~= "") and data.caption or (playerName .. " - captured via LB Phone"),
        videoUrl = data.videoUrl,
        createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ") .. "",
    })

    PerformHttpRequest(siteUrl .. "/api/xonsight/evidence", function(statusCode, responseText)
        local ok = statusCode ~= nil and statusCode >= 200 and statusCode < 300
        TriggerClientEvent("opslabs-bodycam:lbphone:submitResult", src, ok, ok and "Sent to Xon Sight" or ("Failed to submit (" .. tostring(statusCode) .. ")"))
        if not ok then
            log("Evidence submission failed for player", src, statusCode, responseText)
        end
    end, "POST", payload, Modules.Headers())
end)
