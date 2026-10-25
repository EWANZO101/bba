fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'opslabs-bodycam'
author 'OpsLab Systems'
description 'Body worn cameras: records the officer\'s view as video and sends every recording to the Xon Sight evidence portal (live roster on /live), plus the Xon Sight tablet, LB Phone app and live sync modules. Standalone or ESX, QBCore, Qbox, ox_core, ND.'
version '1.1.0'

shared_scripts {
    '@opslabs-license/guard.lua',     -- OPSHUB: every player action is checked (opslabs-license)
    'config.lua',
}

client_scripts {
    'client/chestcam.lua',   -- optional: render from a chest-clipped camera while recording (Config.ChestCam)
    'client/main.lua',
    'client/vest.lua',       -- the black vest + the camera you can see on it (opslabs-props models)

    -- modules (settings: config_server.lua → ServerConfig.Modules, shared to clients by modules/server.lua)
    'modules/client.lua',
    'modules/tablet/client.lua',     -- was xonsight-tablet
    'modules/lbphone/client.lua',    -- was xonsight-lbphone
}

server_scripts {
    'config_server.lua',      -- every setting, the Xon Sight connection and all modules (was also xonsight-config)
    'server/storage.js',      -- writes the video files, serves them over HTTP when nginx doesn't
    'server/bridge.lua',      -- framework: job, duty, name, items (standalone without one)
    'server/xonsight.lua',    -- Xon Sight evidence webhook + live recorder roster
    'server/audio.lua',       -- voice in the videos through the OPS Voice bridge
    'server/main.lua',
    'server/vest.lua',       -- vest item / command

    -- modules
    'modules/server.lua',
    'modules/lbphone/server.lua',    -- was xonsight-lbphone
    'modules/livesync/server.lua',   -- was xonsight-livesync
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/recorder.js',
    'html/hud.css',
    'html/tablet.js',
    'html/tablet.css',
    'html/lbphone/**/*',
}

dependency 'opslabs-license'   -- OPSHUB licensing: nothing runs without it
