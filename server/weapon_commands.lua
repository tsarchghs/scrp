-- Weapon system commands

-- Issue weapon license command
RegisterCommand('giveweaponlicense', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 3) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, 
            "Usage: /giveweaponlicense [playerid] [license_type] [duration_days]")
        return
    end

    local targetId = tonumber(args[1])
    local licenseType = args[2]
    local duration = tonumber(args[3])
    
    if not targetId or not duration then return end
    if not PlayerData[targetId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, "Invalid player ID!")
        return
    end

    issueWeaponLicense(source, targetId, licenseType, duration)
end, false)

-- Phone commands
RegisterCommand('sms', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[PHONE]", { 255, 0, 0 }, 
            "Usage: /sms [number] [message]")
        return
    end

    local targetNumber = args[1]
    local message = table.concat(args, " ", 2)
    
    sendSMS(source, targetNumber, message)
end, false)

RegisterCommand('call', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PHONE]", { 255, 0, 0 }, 
            "Usage: /call [number]")
        return
    end

    local targetNumber = args[1]
    makePhoneCall(source, targetNumber)
end, false)

RegisterCommand('addcontact', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[PHONE]", { 255, 0, 0 }, 
            "Usage: /addcontact [name] [number]")
        return
    end

    local contactName = args[1]
    local contactNumber = args[2]
    
    addContact(source, contactName, contactNumber)
end, false)

-- Medical commands
RegisterCommand('treat', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 255, 0, 0 }, 
            "Usage: /treat [playerid] [treatment]")
        return
    end

    local targetId = tonumber(args[1])
    local treatment = table.concat(args, " ", 2)
    
    if not targetId then return end
    treatPlayer(source, targetId, treatment)
end, false)

RegisterCommand('revive', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 255, 0, 0 }, 
            "Usage: /revive [playerid]")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then return end
    
    revivePlayer(source, targetId)
end, false)

-- Drug commands
RegisterCommand('createlab', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, 
            "Usage: /createlab [drug_type]")
        return
    end

    local drugType = args[1]
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    createDrugLab(source, drugType, coords.x, coords.y, coords.z)
end, false)

RegisterCommand('selldrugs', function(source, args, rawCommand)
    if #args ~= 4 then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, 
            "Usage: /selldrugs [playerid] [drug_type] [quantity] [price]")
        return
    end

    local targetId = tonumber(args[1])
    local drugType = args[2]
    local quantity = tonumber(args[3])
    local price = tonumber(args[4])
    
    if not targetId or not quantity or not price then return end
    sellDrugs(source, targetId, drugType, quantity, price)
end, false)

RegisterCommand('usedrugs', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, 
            "Usage: /usedrugs [drug_type]")
        return
    end

    local drugType = args[1]
    useDrugs(source, drugType)
end, false)

-- Gang commands
RegisterCommand('startwar', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[GANG]", { 255, 0, 0 }, 
            "Usage: /startwar [territory_id]")
        return
    end

    local territoryId = tonumber(args[1])
    if not territoryId then return end
    
    startTerritoryWar(source, territoryId)
end, false)

RegisterCommand('territories', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[TERRITORIES]", { 255, 255, 0 }, "Gang Territories:")
    
    for id, territory in pairs(Territories) do
        local controller = "Unclaimed"
        if territory.controlledBy > 0 and Factions[territory.controlledBy] then
            controller = Factions[territory.controlledBy].Name
        end
        
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s - Controlled by: %s"):format(id, territory.name, controller))
    end
end, false)
