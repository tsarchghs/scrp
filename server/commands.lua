-- Professional Command System with SA-MP Style Feedback
-- All commands require authentication

-- Helper function to check if player is logged in
local function isLoggedIn(source)
    return PlayerData[source] and PlayerData[source].isLoggedIn
end

-- Helper function to check admin level
local function getAdminLevel(source)
    if not isLoggedIn(source) or not PlayerData[source].characterData then
        return 0
    end
    return PlayerData[source].characterData.AdminLevel or 0
end

-- Stats command
RegisterCommand('stats', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    SendPlayerStats(source)
    LogAction(source, "COMMAND_STATS", "Viewed player statistics")
end, false)

-- Help command
RegisterCommand('help', function(source, args, rawCommand)
    SendHelpInfo(source)
    LogAction(source, "COMMAND_HELP", "Viewed help information")
end, false)

-- Players list command
RegisterCommand('players', function(source, args, rawCommand)
    local playerList = {}
    local count = 0
    
    for playerId, data in pairs(PlayerData) do
        if data.isLoggedIn and data.characterData then
            count = count + 1
            table.insert(playerList, {
                id = playerId,
                name = data.characterData.Name,
                level = data.characterData.Level,
                job = data.characterData.JobName or "Unemployed"
            })
        end
    end
    
    SendFormattedMessage(source, "LIGHTBLUE", "", "════════════ ONLINE PLAYERS (" .. count .. ") ════════════")
    
    if count == 0 then
        SendFormattedMessage(source, "WHITE", "", "No players online")
    else
        for _, player in ipairs(playerList) do
            SendFormattedMessage(source, "WHITE", "", 
                string.format("[%d] %s (Level %d) - %s", player.id, player.name, player.level, player.job))
        end
    end
    
    SendFormattedMessage(source, "LIGHTBLUE", "", "═══════════════════════════════════════════")
    LogAction(source, "COMMAND_PLAYERS", "Viewed online players list")
end, false)

-- Time command
RegisterCommand('time', function(source, args, rawCommand)
    local realTime = os.date("%H:%M:%S")
    local gameTime = string.format("%02d:%02d", GetConvarInt("sv_hour", 12), GetConvarInt("sv_minute", 0))
    
    SendFormattedMessage(source, "YELLOW", "» Server Time:", realTime)
    SendFormattedMessage(source, "YELLOW", "» Game Time:", gameTime)
    LogAction(source, "COMMAND_TIME", "Checked server time")
end, false)

-- Money commands
RegisterCommand('givemoney', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    if #args ~= 2 then
        SendErrorMessage(source, "Usage: /givemoney [playerid] [amount]")
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount or amount <= 0 then
        SendErrorMessage(source, "Invalid player ID or amount!")
        return
    end
    
    if not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then
        SendErrorMessage(source, "Target player is not online or logged in!")
        return
    end
    
    local senderData = PlayerData[source].characterData
    local targetData = PlayerData[targetId].characterData
    
    if senderData.Money < amount then
        SendErrorMessage(source, "You don't have enough money!")
        return
    end
    
    -- Transfer money
    senderData.Money = senderData.Money - amount
    targetData.Money = targetData.Money + amount
    
    -- Update database
    MySQL.Async.execute('UPDATE characters SET Money = @money WHERE CharacterID = @id', {
        ['@money'] = senderData.Money,
        ['@id'] = senderData.CharacterID
    })
    
    MySQL.Async.execute('UPDATE characters SET Money = @money WHERE CharacterID = @id', {
        ['@money'] = targetData.Money,
        ['@id'] = targetData.CharacterID
    })
    
    -- Send messages
    SendSuccessMessage(source, string.format("You gave $%d to %s", amount, targetData.Name))
    SendSuccessMessage(targetId, string.format("You received $%d from %s", amount, senderData.Name))
    
    LogAction(source, "MONEY_TRANSFER", string.format("Gave $%d to %s (ID: %d)", amount, targetData.Name, targetId))
    LogAction(targetId, "MONEY_RECEIVE", string.format("Received $%d from %s (ID: %d)", amount, senderData.Name, source))
end, false)

-- Inventory command
RegisterCommand('inventory', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    TriggerServerEvent('scrp:requestInventory')
    LogAction(source, "COMMAND_INVENTORY", "Viewed inventory")
end, false)

-- Chat commands
RegisterCommand('say', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /say [message]")
        return
    end
    
    local message = table.concat(args, " ")
    SendProximityMessage(source, message)
    LogAction(source, "CHAT_SAY", "Said: " .. message)
end, false)

RegisterCommand('shout', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /shout [message]")
        return
    end
    
    local message = table.concat(args, " ")
    SendShoutMessage(source, message)
    LogAction(source, "CHAT_SHOUT", "Shouted: " .. message)
end, false)

RegisterCommand('whisper', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    if #args < 2 then
        SendErrorMessage(source, "Usage: /whisper [playerid] [message]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then
        SendErrorMessage(source, "Invalid player ID or player not online!")
        return
    end
    
    table.remove(args, 1)
    local message = table.concat(args, " ")
    
    SendWhisperMessage(source, targetId, message)
    LogAction(source, "CHAT_WHISPER", string.format("Whispered to %s: %s", PlayerData[targetId].characterData.Name, message))
end, false)

-- Admin commands
RegisterCommand('kick', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /kick [playerid] [reason]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] then
        SendErrorMessage(source, "Invalid player ID!")
        return
    end
    
    table.remove(args, 1)
    local reason = table.concat(args, " ") or "No reason specified"
    local adminName = PlayerData[source].characterData.Name
    local targetName = PlayerData[targetId].characterData.Name
    
    -- Send messages
    SendAdminMessage(targetId, string.format("You have been kicked by %s. Reason: %s", adminName, reason))
    BroadcastMessage("YELLOW", "» Admin:", string.format("%s has been kicked by %s. Reason: %s", targetName, adminName, reason))
    
    -- Kick player
    DropPlayer(targetId, "Kicked by admin: " .. reason)
    
    LogAction(source, "ADMIN_KICK", string.format("Kicked %s (ID: %d) - Reason: %s", targetName, targetId, reason))
end, false)

RegisterCommand('ban', function(source, args, rawCommand)
    if getAdminLevel(source) < 2 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /ban [playerid] [reason]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] then
        SendErrorMessage(source, "Invalid player ID!")
        return
    end
    
    table.remove(args, 1)
    local reason = table.concat(args, " ") or "No reason specified"
    local adminName = PlayerData[source].characterData.Name
    local targetName = PlayerData[targetId].characterData.Name
    local targetAccountId = PlayerData[targetId].accountData.AccountID
    
    -- Add to ban database
    MySQL.Async.execute('INSERT INTO bans (AccountID, AdminName, Reason, BanDate) VALUES (@accountId, @adminName, @reason, NOW())', {
        ['@accountId'] = targetAccountId,
        ['@adminName'] = adminName,
        ['@reason'] = reason
    })
    
    -- Send messages
    SendAdminMessage(targetId, string.format("You have been banned by %s. Reason: %s", adminName, reason))
    BroadcastMessage("RED", "» Admin:", string.format("%s has been banned by %s. Reason: %s", targetName, adminName, reason))
    
    -- Ban player
    DropPlayer(targetId, "Banned by admin: " .. reason)
    
    LogAction(source, "ADMIN_BAN", string.format("Banned %s (ID: %d, Account: %d) - Reason: %s", targetName, targetId, targetAccountId, reason))
end, false)

RegisterCommand('goto', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /goto [playerid]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then
        SendErrorMessage(source, "Invalid player ID or player not online!")
        return
    end
    
    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('scrp:teleportPlayer', source, targetCoords.x, targetCoords.y, targetCoords.z)
    
    SendSuccessMessage(source, string.format("Teleported to %s", PlayerData[targetId].characterData.Name))
    LogAction(source, "ADMIN_GOTO", string.format("Teleported to %s (ID: %d)", PlayerData[targetId].characterData.Name, targetId))
end, false)

RegisterCommand('bring', function(source, args, rawCommand)
    if getAdminLevel(source) < 1 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /bring [playerid]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then
        SendErrorMessage(source, "Invalid player ID or player not online!")
        return
    end
    
    local adminPed = GetPlayerPed(source)
    local adminCoords = GetEntityCoords(adminPed)
    
    TriggerClientEvent('scrp:teleportPlayer', targetId, adminCoords.x, adminCoords.y, adminCoords.z)
    
    SendSuccessMessage(source, string.format("Brought %s to your location", PlayerData[targetId].characterData.Name))
    SendInfoMessage(targetId, string.format("You have been teleported by admin %s", PlayerData[source].characterData.Name))
    
    LogAction(source, "ADMIN_BRING", string.format("Brought %s (ID: %d) to location", PlayerData[targetId].characterData.Name, targetId))
end, false)

-- Vehicle commands
RegisterCommand('v', function(source, args, rawCommand)
    if not isLoggedIn(source) then
        SendErrorMessage(source, "You must be logged in to use this command!")
        return
    end
    
    if getAdminLevel(source) < 1 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        SendErrorMessage(source, "Usage: /v [vehicle_name]")
        return
    end
    
    local vehicleName = args[1]
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    TriggerClientEvent('scrp:spawnVehicle', source, vehicleName, playerCoords.x, playerCoords.y, playerCoords.z, playerHeading)
    
    SendSuccessMessage(source, string.format("Spawned vehicle: %s", vehicleName))
    LogAction(source, "ADMIN_VEHICLE", string.format("Spawned vehicle: %s", vehicleName))
end, false)

-- Economy commands
RegisterCommand('setmoney', function(source, args, rawCommand)
    if getAdminLevel(source) < 2 then
        SendErrorMessage(source, "You don't have permission to use this command!")
        return
    end
    
    if #args < 2 then
        SendErrorMessage(source, "Usage: /setmoney [playerid] [amount]")
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount or amount < 0 then
        SendErrorMessage(source, "Invalid player ID or amount!")
        return
    end
    
    if not PlayerData[targetId] or not PlayerData[targetId].isLoggedIn then
        SendErrorMessage(source, "Target player is not online or logged in!")
        return
    end
    
    local targetData = PlayerData[targetId].characterData
    local oldAmount = targetData.Money
    targetData.Money = amount
    
    -- Update database
    MySQL.Async.execute('UPDATE characters SET Money = @money WHERE CharacterID = @id', {
        ['@money'] = amount,
        ['@id'] = targetData.CharacterID
    })
    
    SendSuccessMessage(source, string.format("Set %s's money to $%d (was $%d)", targetData.Name, amount, oldAmount))
    SendInfoMessage(targetId, string.format("Your money has been set to $%d by an admin", amount))
    
    LogAction(source, "ADMIN_SETMONEY", string.format("Set %s's money to $%d (was $%d)", targetData.Name, amount, oldAmount))
end, false)

print("^2[SC:RP] Commands system loaded successfully!^0")
