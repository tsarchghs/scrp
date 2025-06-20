-- server/commands.lua
-- Merged Professional Command System

-- =============================================================================
-- >> HELPER & PLACEHOLDER FUNCTIONS (Implement in your core script)
-- =============================================================================

-- Global PlayerData table (ensure this is initialized elsewhere)
PlayerData = PlayerData or {}

-- Helper function to send error messages to the client
local function SendErrorMessage(source, message)
    TriggerClientEvent('chatMessage', source, "[ERROR]", "FF0000", message)
end

-- Helper function to send success messages to the client
local function SendSuccessMessage(source, message)
    TriggerClientEvent('chatMessage', source, "[SUCCESS]", "00FF00", message)
end

-- Placeholder functions required by the commands below
-- You must implement the logic for these in your framework.
local function SendInfoMessage(source, message) print("INFO: " .. message) TriggerClientEvent('chatMessage', source, "[INFO]", "3399FF", message) end
local function SendFormattedMessage(source, color, prefix, message) print(prefix .. " " .. message) TriggerClientEvent('chatMessage', source, prefix, "FFFFFF", message) end
local function SendAdminMessage(source, message) print("ADMIN MSG: " .. message) TriggerClientEvent('chatMessage', source, "[ADMIN]", "FFD700", message) end
local function BroadcastMessage(color, prefix, message) print("BROADCAST: " .. prefix .. " " .. message) TriggerClientEvent('chatMessage', -1, prefix, "FFFFFF", message) end
local function LogAction(source, action, details) print(string.format("[LOG] Player %s | %s | %s", source, action, details)) end
local function SendPlayerStats(source) SendInfoMessage(source, "This is where the player's stats would be displayed.") end
local function SendHelpInfo(source) SendInfoMessage(source, "This is where help information would be displayed.") end
local function SendProximityMessage(source, message) print(string.format("[SAY] %s: %s", GetPlayerName(source), message)) end
local function SendShoutMessage(source, message) print(string.format("[SHOUT] %s: %s", GetPlayerName(source), message)) end
local function SendWhisperMessage(source, targetId, message) print(string.format("[WHISPER] %s to %s: %s", GetPlayerName(source), GetPlayerName(targetId), message)) end

-- =============================================================================
-- >> PERMISSION & STATE CHECKS
-- =============================================================================

-- Helper function to check if player is logged in
local function isLoggedIn(source)
    if PlayerData[source] and PlayerData[source].isLoggedIn then
        return true
    else
        SendErrorMessage(source, "You must be logged in to use this command!")
        return false
    end
end

-- Helper function to check admin level
local function getAdminLevel(source)
    if not isLoggedIn(source) or not PlayerData[source].characterData then
        return 0
    end
    return PlayerData[source].characterData.AdminLevel or 0
end

-- =============================================================================
-- >> GENERAL COMMANDS
-- =============================================================================

RegisterCommand('coords', function(source, args, rawCommand)
    TriggerClientEvent('getCoords', source) -- Tells the client to fetch and display coordinates
end, false)

RegisterCommand('stats', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    SendPlayerStats(source)
    LogAction(source, "COMMAND_STATS", "Viewed player statistics")
end, false)

RegisterCommand('help', function(source, args, rawCommand)
    SendHelpInfo(source)
    LogAction(source, "COMMAND_HELP", "Viewed help information")
end, false)

RegisterCommand('players', function(source, args, rawCommand)
    local playerList = {}
    local count = 0
    for i = 0, 255 do -- Iterate through all possible player IDs
        if GetPlayerName(i) then -- Check if player exists
            local pData = PlayerData[i]
            if pData and pData.isLoggedIn and pData.characterData then
                count = count + 1
                table.insert(playerList, string.format("[%d] %s (Level %d)", i, pData.characterData.Name, pData.characterData.Level or 1))
            end
        end
    end
    
    SendFormattedMessage(source, "LIGHTBLUE", "", "═════ ONLINE PLAYERS (" .. count .. ") ═════")
    if count == 0 then
        SendFormattedMessage(source, "WHITE", "", "No other players are online.")
    else
        for _, playerString in ipairs(playerList) do
            SendFormattedMessage(source, "WHITE", "", playerString)
        end
    end
    LogAction(source, "COMMAND_PLAYERS", "Viewed online players list")
end, false)

RegisterCommand('time', function(source, args, rawCommand)
    local realTime = os.date("%H:%M:%S (CET)")
    SendFormattedMessage(source, "YELLOW", "» Server Time:", realTime)
    LogAction(source, "COMMAND_TIME", "Checked server time")
end, false)

RegisterCommand('inventory', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    TriggerServerEvent('scrp:requestInventory', source) -- Assuming you have an inventory script listening for this
    LogAction(source, "COMMAND_INVENTORY", "Viewed inventory")
end, false)

-- =============================================================================
-- >> ECONOMY & INTERACTION COMMANDS
-- =============================================================================

RegisterCommand('givemoney', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    if #args ~= 2 then return SendErrorMessage(source, "USAGE: /givemoney [player_id] [amount]") end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not GetPlayerName(targetId) then return SendErrorMessage(source, "Invalid Player ID.") end
    if not amount or amount <= 0 then return SendErrorMessage(source, "Invalid amount.") end
    if not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then return SendErrorMessage(source, "Target player is not logged in.") end

    local senderData = PlayerData[source].characterData
    if senderData.Money < amount then return SendErrorMessage(source, "You don't have enough money.") end
    
    local targetData = PlayerData[targetId].characterData
    senderData.Money = senderData.Money - amount
    targetData.Money = targetData.Money + amount
    
    -- In a real scenario, you would save this to the database
    -- MySQL.Async.execute(...)

    SendSuccessMessage(source, string.format("You gave $%d to %s.", amount, targetData.Name))
    SendSuccessMessage(targetId, string.format("%s gave you $%d.", senderData.Name, amount))
    LogAction(source, "MONEY_TRANSFER", string.format("Gave $%d to %s (ID: %d)", amount, targetData.Name, targetId))
end, false)

-- =============================================================================
-- >> CHAT COMMANDS
-- =============================================================================

RegisterCommand('say', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    if #args < 1 then return SendErrorMessage(source, "USAGE: /say [message]") end
    SendProximityMessage(source, table.concat(args, " "))
end, false)

RegisterCommand('shout', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    if #args < 1 then return SendErrorMessage(source, "USAGE: /shout [message]") end
    SendShoutMessage(source, table.concat(args, " "))
end, false)

RegisterCommand('whisper', function(source, args, rawCommand)
    if not isLoggedIn(source) then return end
    if #args < 2 then return SendErrorMessage(source, "USAGE: /whisper [player_id] [message]") end
    
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return SendErrorMessage(source, "Invalid Player ID.") end
    if not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then return SendErrorMessage(source, "Target player is not logged in.") end

    table.remove(args, 1)
    local message = table.concat(args, " ")
    SendWhisperMessage(source, targetId, message)
end, false)

-- =============================================================================
-- >> ADMIN COMMANDS
-- =============================================================================

RegisterCommand('kick', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    if #args < 2 then return SendErrorMessage(source, "USAGE: /kick [player_id] [reason]") end
    
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return SendErrorMessage(source, "Invalid Player ID.") end

    table.remove(args, 1)
    local reason = table.concat(args, " ")
    local adminName = PlayerData[source].characterData.Name
    local targetName = GetPlayerName(targetId)
    
    BroadcastMessage("YELLOW", "» ADMIN:", string.format("%s has been kicked by %s. (Reason: %s)", targetName, adminName, reason))
    DropPlayer(targetId, "You have been kicked by an admin. Reason: " .. reason)
    LogAction(source, "ADMIN_KICK", string.format("Kicked %s (ID: %d). Reason: %s", targetName, targetId, reason))
end, false)

RegisterCommand('ban', function(source, args, rawCommand)
    if getAdminLevel(source) < 2 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    -- Ban logic would be implemented here, similar to kick but with database interaction.
    SendInfoMessage(source, "Ban command placeholder.")
end, false)

RegisterCommand('goto', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    if #args < 1 then return SendErrorMessage(source, "USAGE: /goto [player_id]") end
    
    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return SendErrorMessage(source, "Invalid Player ID.") end

    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    SetEntityCoords(GetPlayerPed(source), targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
    SendSuccessMessage(source, "Teleported to player.")
    LogAction(source, "ADMIN_GOTO", "Teleported to player " .. targetId)
end, false)

RegisterCommand('bring', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    if #args < 1 then return SendErrorMessage(source, "USAGE: /bring [player_id]") end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then return SendErrorMessage(source, "Invalid Player ID.") end

    local sourceCoords = GetEntityCoords(GetPlayerPed(source))
    SetEntityCoords(GetPlayerPed(targetId), sourceCoords.x, sourceCoords.y, sourceCoords.z, false, false, false, true)
    SendSuccessMessage(source, "Brought player to you.")
    SendInfoMessage(targetId, "You have been teleported by an admin.")
    LogAction(source, "ADMIN_BRING", "Brought player " .. targetId)
end, false)

RegisterCommand('v', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    if #args < 1 then return SendErrorMessage(source, "USAGE: /v [model_name]") end
    
    local vehicleName = args[1]
    TriggerClientEvent('scrp:spawnVehicle', source, vehicleName) -- Client-side spawning is often better
    SendSuccessMessage(source, "Spawning vehicle: " .. vehicleName)
    LogAction(source, "ADMIN_VEHICLE", "Spawned vehicle " .. vehicleName)
end, false)

RegisterCommand('setmoney', function(source, args, rawCommand)
    if getAdminLevel(source) < 2 then return SendErrorMessage(source, "You do not have permission to use this command.") end
    -- Set money logic would be implemented here.
    SendInfoMessage(source, "Setmoney command placeholder.")
end, false)

-- =============================================================================
-- >> SCRIPT LOADED
-- =============================================================================

print("^2[CMDS] Merged command system loaded successfully.^0")