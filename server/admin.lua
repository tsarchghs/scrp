-- Admin command system

AdminLevels = {
    [1] = "Helper",
    [2] = "Moderator", 
    [3] = "Administrator",
    [4] = "Senior Administrator",
    [5] = "Head Administrator"
}

-- Function to check if player is admin
function isPlayerAdmin(source, level)
    if not PlayerData[source] then return false end
    -- This should check the AdminLevel from the account table
    return true -- Temporary, implement proper admin level checking
end

-- Admin teleport command
RegisterCommand('goto', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 1) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission to use this command!")
        return
    end
    
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Usage: /goto [playerid]")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Invalid player ID!")
        return
    end

    local targetPos = GetEntityCoords(GetPlayerPed(targetId))
    TriggerClientEvent('scrp:teleportPlayer', source, targetPos.x, targetPos.y, targetPos.z)
    TriggerClientEvent('chatMessage', source, "[ADMIN]", { 0, 255, 0 }, 
        ("Teleported to %s"):format(PlayerData[targetId].Name))
end, false)

-- Admin get here command
RegisterCommand('gethere', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 1) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission to use this command!")
        return
    end
    
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Usage: /gethere [playerid]")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not PlayerData[targetId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Invalid player ID!")
        return
    end

    local adminPos = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('scrp:teleportPlayer', targetId, adminPos.x, adminPos.y, adminPos.z)
    TriggerClientEvent('chatMessage', source, "[ADMIN]", { 0, 255, 0 }, 
        ("Brought %s to your location"):format(PlayerData[targetId].Name))
    TriggerClientEvent('chatMessage', targetId, "[ADMIN]", { 255, 255, 0 }, 
        ("You were teleported by an administrator"))
end, false)

-- Admin kick command
RegisterCommand('kick', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 2) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Usage: /kick [playerid] [reason]")
        return
    end

    local targetId = tonumber(args[1])
    local reason = table.concat(args, " ", 2) or "No reason specified"
    
    if not targetId or not PlayerData[targetId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Invalid player ID!")
        return
    end

    DropPlayer(targetId, ("Kicked by administrator: %s"):format(reason))
    TriggerClientEvent('chatMessage', -1, "[ADMIN]", { 255, 255, 0 }, 
        ("%s was kicked by an administrator. Reason: %s"):format(PlayerData[targetId].Name, reason))
end, false)

-- Admin ban command
RegisterCommand('ban', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 3) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission to use this command!")
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Usage: /ban [playerid] [reason]")
        return
    end

    local targetId = tonumber(args[1])
    local reason = table.concat(args, " ", 2) or "No reason specified"
    
    if not targetId or not PlayerData[targetId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Invalid player ID!")
        return
    end

    local targetAccountId = PlayerData[targetId].AccountID
    local query = [[
        UPDATE `accounts` SET `Banned` = 1, `BanReason` = @reason WHERE `ID` = @accountId
    ]]

    MySQL.query(query, {
        ['@reason'] = reason,
        ['@accountId'] = targetAccountId
    }, function(rows, affected)
        if affected > 0 then
            DropPlayer(targetId, ("Banned by administrator: %s"):format(reason))
            TriggerClientEvent('chatMessage', -1, "[ADMIN]", { 255, 255, 0 }, 
                ("%s was banned by an administrator. Reason: %s"):format(PlayerData[targetId].Name, reason))
        end
    end)
end, false)

-- Admin spawn vehicle command
RegisterCommand('v', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 1) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission to use this command!")
        return
    end
    
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Usage: /v [vehicle_name]")
        return
    end

    local vehicleName = args[1]
    TriggerClientEvent('scrp:spawnAdminVehicle', source, vehicleName)
end, false)
