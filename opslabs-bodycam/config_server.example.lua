-- This file ships ready to edit directly - no copy step needed. (If you ever want a clean
-- reference copy, config_server.example.lua next to this has the same content.)
ServerConfig = {}

-- ============================================================================
--  REQUIRED - the barebones setup: record on the officer's view, upload the
--  finished clip to your Xon Sight portal. Everything below this section is
--  optional and OFF by default - skip it until you actually want it.
-- ============================================================================

ServerConfig.XonSight = {
    -- The one place the portal connection is set: the bodycam and every module below (tablet, LB Phone app,
    -- live sync) use it. Set Key OR Token, not both.
    Url = 'https://xonsight.opslabsystems.cloud',   -- your evidence portal's address, no trailing slash
    -- Most people: a single server on its own portal. Matches XONSIGHT_WEBHOOK_KEY in the portal's .env.
    Key = '',                    -- sent as X-XonSight-Key
    -- Only if the portal hosts several servers/communities, or you signed up your community at the portal's
    -- /get-started page: your community's token (from /admin/communities or /integration). Wins over Key.
    Token = '',                  -- sent as X-XonSight-Token
    LiveSync = true,             -- keep /live up to date with who is recording
    SyncSeconds = 5,
    -- Evidence ids must be unique on the portal. They start here, so they never meet the ids another source
    -- (e.g. the XonSight resource) sends to the same portal.
    EvidenceIdOffset = 1000000,
    ServerTag = '',              -- put in front of every caption when several servers share one portal, e.g. 'S1'
    -- trigger (session.trigger, e.g. the auto-start reasons below) -> alert sent to the portal's Live page
    -- (POST /api/xonsight/alerts - an extension endpoint, not every Xon Sight deployment has it). Anything not
    -- listed here never fires an alert - keep it short, or routine triggers like sirens become noise on /live.
    -- AlertTriggers = {
    --     ['shots fired']  = { type = 'weapon_fired', message = 'Shots fired' },
    --     ['weapon drawn'] = { type = 'weapon_drawn', message = 'Weapon drawn' },
    -- },
}

-- Where the videos are kept. The portal only stores a link, so the files must be reachable from the internet over
-- https (the portal is https: a plain http video link won't play there). See README.md's Install section, step 3.
ServerConfig.Storage = {
    -- folder for the .webm files. '' = <this resource>/media. FXServer only lets a resource write inside resource
    -- folders, so anything else must be a resource's folder (e.g. a dedicated storage resource)
    Dir = '',
    -- public https address of the videos, no trailing slash: a web server publishing the folder from disk (README).
    -- Required: FXServer itself doesn't serve them (sending video from a resource crashed the game server)
    PublicUrl = '',
    MaxSegmentMB = 64,           -- larger uploads are refused
}

-- Log recordings in MySQL (oxmysql, table created by itself) and retry evidence the portal didn't take.
-- Without oxmysql it still works; failed sends are then only retried until the next restart.
ServerConfig.Database = true

-- ============================================================================
--  OPTIONAL - all off by default. The bodycam records and uploads fine with
--  none of this touched; only come back here if you specifically want one
--  of these extras and have its dependency running.
-- ============================================================================

-- Real-time live video (MediaMTX WHIP publish, Config.LiveStream client-side) - a dashcam/bodycam toggle an
-- officer can start separately from normal recording, watchable on the portal's /live page while it's
-- happening. Needs a MediaMTX server you run yourself; WhipUrlFormat is where the NUI POSTs its SDP offer,
-- %s standing in for the per-session path Xon Sight hands back from /api/xonsight/live/start - e.g.
-- 'https://media.example.com:8889/%s/whip'. Leave Enabled = false (default) if you don't have MediaMTX set
-- up - nothing else breaks, the dashcam toggle just tells the officer live video isn't available here.
ServerConfig.LiveStream = {
    Enabled = false,
    WhipUrlFormat = '',
}

-- Voice in the videos (the officer's mic, people talking near them, radio) through the separate OPS Voice
-- bridge (/opt/opsvoip-bridge, a Node.js service you run yourself - not included here). Needs the OPS Voice
-- convars opsvoip_url / opsvoip_key set. Leave Enabled = false (default) if you don't run that bridge -
-- recordings still work, they just come out silent.
ServerConfig.Audio = {
    Enabled = false,
    PublicUrl = '',      -- where the bridge's videos with sound are served (nginx → /var/lib/opsvoip-bridge/bodycam)
    KeepSilentCopy = false,    -- keep the video-only file as well
}

-- Voice commands ("xonsight on"/"xonsight off") through the officer's own push-to-talk mic - same OPS Voice
-- bridge connection as Audio above (requires Audio.Enabled too), using a local/offline speech-to-text model
-- (no cloud API, no per-use cost, runs on the bridge server's own CPU). Only ever hears the recording officer's
-- own mic, never bystanders or radio traffic also heard in their channel. Phrases are matched case-insensitively
-- as a substring of what was heard, so minor misrecognition ("exon sight on") still works; keep them distinct
-- from each other and from ordinary radio chatter. Leave Enabled = false (default) along with Audio above.
ServerConfig.VoiceCommand = {
    Enabled = false,
    OnPhrases = { 'xonsight on', 'xon sight on', 'xon on' },
    OffPhrases = { 'xonsight off', 'xon sight off', 'xon off' },
}

-- ============================================================================
--  MODULES - the former xonsight-tablet / xonsight-lbphone / xonsight-livesync
--  resources, now part of this one (modules/). They use the portal connection
--  from ServerConfig.XonSight above. Only the non-secret settings below reach
--  players' games (modules/server.lua shares them) - Key/Token never do.
-- ============================================================================

ServerConfig.Modules = {
    -- In-game tablet (stock prop + NUI) that opens the portal.
    Tablet = {
        Enabled = true,
        -- Path opened inside the tablet: '/dashboard', or '/live' to land straight on the live recorder map.
        -- The officer logs in inside the tablet like a normal browser tab; the NUI keeps its cookies between uses.
        StartPath = '/dashboard',
        -- Key that opens/closes it (FiveM control name: https://docs.fivem.net/docs/game-references/controls/).
        -- Players can rebind it in Settings → Key Bindings → FiveM.
        ToggleKey = 'F6',
        -- Stock GTA V tablet prop - no custom model needed.
        PropModel = 'prop_cs_tablet',
        -- Bone the prop attaches to and its offset/rotation, tuned for prop_cs_tablet in the left hand.
        AttachBone = 'PH_L_Hand',
        AttachOffset = { x = 0.03, y = 0.02, z = 0.0 },
        AttachRotation = { x = 0.0, y = 0.0, z = 0.0 },
        -- Restrict by job (wire GetPlayerJob() in modules/tablet/client.lua to your framework). Empty = anyone.
        AllowedJobs = {},
        -- No attacking/aiming while it's open (both hands on the tablet). Walking stays enabled.
        DisableAttackWhileOpen = true,
    },

    -- Xon Sight as an installable LB Phone app (registered through lb-phone's AddCustomApp export).
    LbPhone = {
        Enabled = true,
        Identifier = 'xonsight',
        Name = 'Xon Sight',
        Description = 'Bodycam evidence, live ops map, and cases - straight from your phone.',
        Developer = 'Xon Sight Evidence Portal',
        StartPath = '/dashboard',    -- page that opens first inside the app
        DefaultApp = false,          -- true = on every phone already, no app store download
        Price = nil,                 -- in-game price in the app store, nil = free
        Size = 4096,                 -- store listing size (kb), cosmetic only
        -- false = hide the in-app "Record evidence" button and only use the app as a viewer.
        AllowCapture = true,
    },

    -- Pushes the separate XonSight resource's active recorders (exports.XonSight:GetActiveRecorders()) to the
    -- portal's /live page. Off by default: this resource already keeps /live up to date with its own recorders
    -- (ServerConfig.XonSight.LiveSync), and the portal replaces the whole roster on every sync, so running both
    -- makes them overwrite each other. Only turn it on if you run the XonSight resource instead of the bodycam's
    -- own live sync.
    LiveSync = {
        Enabled = false,
        PollIntervalMs = 5000,       -- how often to push the roster
        Debug = false,               -- print sync failures to the server console
    },
}
