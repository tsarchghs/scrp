fx_version 'cerulean'
game 'gta5'

description 'South Central Roleplay - Professional SA-MP Style FiveM Server'
version '3.0.0'
author 'SCRP Development Team'

-- Server Scripts (Critical Load Order)
server_scripts {
    -- MySQL dependency (must be first)
    '@mysql-async/lib/MySQL.lua',
    
    -- Core system files (load in order)
    'server/config.lua',
    'server/database.lua',
    'server/chat_system.lua',
    
    -- Authentication and player management
    'server/account.lua',
    'server/player.lua',
    
    -- Core gameplay systems
    'server/commands.lua',
    'server/admin.lua',
    'server/inventory.lua',
    'server/banking.lua',
    'server/vehicles.lua',
    'server/properties.lua',
    
    -- Faction and organization systems
    'server/factions.lua',
    'server/gangs.lua',
    'server/jobs.lua',
    'server/businesses.lua',
    
    -- Weapon and combat systems
    'server/weapons.lua',
    'server/drugs.lua',
    'server/medical.lua',
    
    -- Basic features
    'server/racing.lua',
    'server/casino_system.lua',
    'server/prison.lua',
    'server/crafting.lua',
    'server/phone.lua',
    'server/trucking_system.lua',
    'server/hitman.lua',
    'server/turf_wars.lua',
    'server/skills.lua',
    
    -- Advanced features (load after core tables exist)
    'server/court_system.lua',
    'server/advanced_housing.lua',
    
    -- Enhanced systems
    'server/enhanced_zones.lua',
    'server/enhanced_commands.lua',
    
    -- Command modules
    'server/business_commands.lua',
    'server/housing_commands.lua',
    'server/racing_commands.lua',
    'server/weapon_commands.lua',
    
    -- Main handler (load last)
    'server/main.lua'
}

-- Client Scripts
client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/properties.lua',
    'client/effects.lua',
    'client/zone_hud.lua'
}

-- UI Configuration
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Resource Dependencies
dependencies {
    'mysql-async'
}

-- Modern FiveM Features
lua54 'yes'

-- Server-only files (security)
server_only_files {
    'server/config.lua',
    'server/database.lua'
}

-- Public exports for other resources
exports {
    'GetPlayerData',
    'IsPlayerLoggedIn',
    'SendServerMessage',
    'LogAction',
    'GetPlayerMoney',
    'UpdatePlayerMoney'
}

-- Server exports
server_exports {
    'GetPlayerAccount',
    'GetPlayerCharacter',
    'SavePlayerData',
    'GetPlayerBySource',
    'IsPlayerAdmin',
    'SendAdminMessage'
}
