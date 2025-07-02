fx_version 'cerulean'
game 'gta5'

author 'Kilo Code'
description 'Player Authentication System'
version '1.0.0'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

files {
    'users.sql'
}

-- Make sure to load this resource before other resources that depend on it.
-- For example, in your server.cfg:
-- ensure authentication
-- ensure fishing