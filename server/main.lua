-- FiveM Server Script for South Central Roleplay
-- mysql-async version 3.3.2 compatible with FiveM artifact 15859

-- Load configuration using FiveM's LoadResourceFile
local configFile = LoadResourceFile(GetCurrentResourceName(), 'server/config.lua')
if configFile then
    load(configFile)()
else
    print("[SC:RP] ERROR: Could not load server/config.lua")

    -- Inline configuration (fallback)
    Config = {}
    Config.DatabaseHost = "127.0.0.1"
    Config.DatabaseUser = "root"
    Config.DatabaseName = "scrp"
    Config.DatabasePassword = ""
    Config.DatabasePort = 3306
    Config.MaxPlayers = 32
    Config.ServerName = "South Central Roleplay"
    Config.DefaultMoney = 5000
    Config.DefaultBank = 10000
    Config.RespawnTime = 30
    Config.JailTime = 300
    Config.MaxInventorySlots = 50
    Config.MaxVehicles = 5
    Config.PropertyTax = 100
    Config.BusinessTax = 500
    Config.EnableTurfWars = true
    Config.EnableRacing = true
    Config.EnablePrison = true
    Config.EnableHitman = true
    Config.EnableSkills = true
    Config.EnableCrafting = true
    Config.EnableGovernment = true
    Config.EnableElections = true
    Config.EnableAdvancedHousing = true
    Config.EnableTrucking = true
    Config.EnableCasino = true
    Config.EnableCourtSystem = true
end

-- Load all modules using LoadResourceFile and load() to avoid require path issues
local function loadModule(modulePath)
    local file = LoadResourceFile(GetCurrentResourceName(), modulePath)
    if file then
        local chunk, err = load(file)
        if chunk then
            chunk()
            print("[SC:RP] Loaded module: " .. modulePath)
            return true
        else
            print("[SC:RP] Error loading module " .. modulePath .. ": " .. tostring(err))
            return false
        end
    else
        print("[SC:RP] Could not find module: " .. modulePath)
        return false
    end
end

-- Load all server modules
loadModule('server/database.lua')
loadModule('server/account.lua')
loadModule('server/player.lua')
loadModule('server/inventory.lua')
loadModule('server/factions.lua')
loadModule('server/jobs.lua')
loadModule('server/vehicles.lua')
loadModule('server/properties.lua')
loadModule('server/banking.lua')
loadModule('server/weapons.lua')
loadModule('server/phone.lua')
loadModule('server/medical.lua')
loadModule('server/drugs.lua')
loadModule('server/gangs.lua')
loadModule('server/businesses.lua')
loadModule('server/skills.lua')
loadModule('server/crafting.lua')
loadModule('server/government.lua')
loadModule('server/turf_wars.lua')
loadModule('server/racing.lua')
loadModule('server/prison.lua')
loadModule('server/hitman.lua')
loadModule('server/admin.lua')
loadModule('server/commands.lua')
loadModule('server/weapon_commands.lua')
loadModule('server/business_commands.lua')
loadModule('server/racing_commands.lua')

-- Initialize all systems on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000) -- Wait for mysql-async to be ready
        connectToDatabase()
        initializeDatabase()
        initializePropertiesTable()
        initializeBankingTables()
        initializeWeaponTables()
        initializePhoneTables()
        initializeMedicalTables()
        initializeDrugTables()
        initializeGangTables()
        initializeBusinessTables()
        initializeSkillsTable()
        initializeCraftingTables()
        initializeGovernmentTables()
        initializeTurfWarTables()
        initializeRacingTables()
        initializePrisonTables()
        initializeHitmanTables()
        
        loadFactions()
        loadProperties()
        loadVehicles()
        loadBusinesses()
        loadCraftingStations()
        loadGovernment()
        loadTurfData()
        loadRaces()
        loadContracts()
        
        print("[SC:RP] All systems initialized successfully!")
        print("[SC:RP] Using mysql-async version 3.3.2")
        print("[SC:RP] Compatible with FiveM artifact 15859")
        print("[SC:RP] Advanced Features: Turf Wars, Racing, Prison, Hitman System")
    end
end)

-- Enhanced player data loading with all systems
AddEventHandler('playerJoining', function(source)
    print(('Player joining: %s'):format(GetPlayerName(source)))
    
    -- Send comprehensive welcome message
    TriggerClientEvent('chatMessage', source, "[SC:RP]", { 255, 255, 0 }, 
        "Welcome to South Central Roleplay - Complete Edition!")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Basic: /login, /createaccount, /createchar, /stats, /inventory, /skills")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Business: /businesses, /buybusiness, /hire, /fire, /buy, /restock")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Turf Wars: /captureturf, /turfinfo, /turfs")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Racing: /races, /createrace, /joinrace, /bet")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Prison: /work, /fight, /prisoninfo")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Hitman: /contract, /contracts, /acceptcontract, /hitmaninfo")
end)

-- Enhanced player data saving with all systems
AddEventHandler('playerDropped', function(reason)
    local player = source
    if PlayerData[player] then
        print(('Player dropped: %s'):format(PlayerData[player].Name))
        savePlayerData(player)
        savePlayerSkills(player)
        savePrisonData(player)
        saveHitmanData(player)
        PlayerData[player] = nil
        PlayerSkills[player] = nil
        PrisonData[player] = nil
        HitmanData[player] = nil
    end
end)

-- Enhanced character loading with all systems
RegisterNetEvent('scrp:selectCharacter')
AddEventHandler('scrp:selectCharacter', function(characterId)
    local player = source
    loadPlayerData(player, characterId)
    loadPlayerSkills(player, characterId)
    loadPrisonData(player, characterId)
    loadHitmanData(player, characterId)
end)

-- Handle player death for various systems
AddEventHandler('baseevents:onPlayerDied', function(killerId, deathCause)
    local player = source
    
    if killerId and killerId ~= player then
        -- Handle turf war deaths
        handleTurfWarDeath(killerId, player)
        
        -- Handle hitman contract completion
        completeContract(killerId, player)
        
        -- Log combat for weapons system
        if deathCause then
            logCombat(PlayerData[killerId] and PlayerData[killerId].CharacterID or 0, 
                     PlayerData[player] and PlayerData[player].CharacterID or 0, 
                     deathCause, 100, 0, 0)
        end
    end
end)

-- Auto-save enhanced with all systems
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        for player, _ in pairs(PlayerData) do
            savePlayerData(player)
            savePlayerSkills(player)
            savePrisonData(player)
            saveHitmanData(player)
            
            -- Save vehicle data for spawned vehicles
            for vehicle, vehicleId in pairs(SpawnedVehicles) do
                saveVehicleData(vehicleId)
            end
        end
        print("[SC:RP] Auto-saved all player data and systems")
    end
end)

-- Player connecting event to initialize player data
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local player = source
    PlayerData[player] = {
        isLoggedIn = false,
        accountData = nil,
        characterData = nil
    }
end)

-- Player loaded event to update player data
RegisterNetEvent('scrp:playerLoaded')
AddEventHandler('scrp:playerLoaded', function(accountData, characterData)
    local player = source
    PlayerData[player].isLoggedIn = true
    PlayerData[player].accountData = accountData
    PlayerData[player].characterData = characterData
end)

print("[SC:RP] Complete main server script loaded successfully!")
print("[SC:RP] Features: Businesses, Skills, Crafting, Government, Elections")
print("[SC:RP] Advanced: Turf Wars, Racing, Prison, Hitman Contracts")
print("[SC:RP] Database: mysql-async 3.3.2 compatible with FiveM 15859")
