-- Racing and Prison Commands

-- Racing commands
RegisterCommand('createrace', function(source, args, rawCommand)
    if #args < 5 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            "Usage: /createrace [name] [laps] [buyin] [max_participants] [vehicle_class]")
        return
    end

    local name = args[1]
    local laps = tonumber(args[2])
    local buyIn = tonumber(args[3])
    local maxParticipants = tonumber(args[4])
    local vehicleClass = tonumber(args[5])
    
    if not laps or not buyIn or not maxParticipants or not vehicleClass then return end
    
    createRace(source, name, laps, buyIn, maxParticipants, vehicleClass)
end, false)

RegisterCommand('addcheckpoint', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            "Usage: /addcheckpoint [race_id]")
        return
    end

    local raceId = tonumber(args[1])
    if not raceId then return end
    
    addRaceCheckpoint(source, raceId)
end, false)

RegisterCommand('startrace', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            "Usage: /startrace [race_id]")
        return
    end

    local raceId = tonumber(args[1])
    if not raceId then return end
    
    startRace(source, raceId)
end, false)

RegisterCommand('joinrace', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            "Usage: /joinrace [race_id]")
        return
    end

    local raceId = tonumber(args[1])
    if not raceId then return end
    
    joinRace(source, raceId)
end, false)

RegisterCommand('bet', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            "Usage: /bet [race_id] [character_id] [amount]")
        return
    end

    local raceId = tonumber(args[1])
    local targetCharacterId = tonumber(args[2])
    local amount = tonumber(args[3])
    
    if not raceId or not targetCharacterId or not amount then return end
    
    placeBet(source, raceId, targetCharacterId, amount)
end, false)

RegisterCommand('races', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[RACES]", { 255, 255, 0 }, "Available Races:")
    
    for id, race in pairs(Races) do
        local status = "Available"
        if ActiveRaces[id] then
            status = ActiveRaces[id].status
        end
        
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s - %d laps - $%d buy-in - %s"):format(id, race.Name, race.Laps, race.BuyIn, status))
    end
end, false)

-- Prison commands
RegisterCommand('jail', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 2) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, 
            "Usage: /jail [player_id] [minutes] [crime]")
        return
    end

    local targetId = tonumber(args[1])
    local minutes = tonumber(args[2])
    local crime = table.concat(args, " ", 3)
    
    if not targetId or not minutes then return end
    
    jailPlayer(source, targetId, crime, minutes, PlayerData[source].CharacterID)
end, false)

RegisterCommand('unjail', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 2) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, 
            "Usage: /unjail [player_id]")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then return end
    
    releasePlayer(targetId)
end, false)

RegisterCommand('work', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, 
            "Usage: /work [job_type] (laundry, kitchen, cleaning, library)")
        return
    end

    local jobType = args[1]
    completePrisonJob(source, jobType)
end, false)

RegisterCommand('fight', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, 
            "Usage: /fight [player_id]")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then return end
    
    startPrisonFight(source, targetId)
end, false)

RegisterCommand('prisoninfo', function(source, args, rawCommand)
    if not PlayerData[source] or not PrisonData[source] then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, "Prison data not loaded!")
        return
    end
    
    local data = PrisonData[source]
    TriggerClientEvent('chatMessage', source, "[PRISON INFO]", { 255, 255, 0 }, "Your Prison Statistics:")
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Reputation: %d | Respect: %d"):format(data.reputation, data.respect))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Fights: %d | Jobs Completed: %d"):format(data.fights, data.jobsCompleted))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Time Served: %d seconds"):format(data.timeServed))
end, false)

-- Hitman commands
RegisterCommand('contract', function(source, args, rawCommand)
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, 
            "Usage: /contract [target_character_id] [reward] [duration_hours] [reason]")
        return
    end

    local targetCharacterId = tonumber(args[1])
    local reward = tonumber(args[2])
    local durationHours = tonumber(args[3])
    local reason = table.concat(args, " ", 4) or "No reason specified"
    
    if not targetCharacterId or not reward or not durationHours then return end
    
    createContract(source, targetCharacterId, reward, reason, durationHours)
end, false)

RegisterCommand('acceptcontract', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, 
            "Usage: /acceptcontract [contract_id]")
        return
    end

    local contractId = tonumber(args[1])
    if not contractId then return end
    
    acceptContract(source, contractId)
end, false)

RegisterCommand('contracts', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[CONTRACTS]", { 255, 255, 0 }, "Available Contracts:")
    
    for id, contract in pairs(Contracts) do
        if contract.Status == "open" then
            TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
                ("%d. Target: %s - Reward: $%d - Reason: %s"):format(id, contract.TargetName, contract.Reward, contract.Reason or "None"))
        end
    end
end, false)

RegisterCommand('hitmaninfo', function(source, args, rawCommand)
    if not PlayerData[source] or not HitmanData[source] then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "Hitman data not loaded!")
        return
    end
    
    local data = HitmanData[source]
    TriggerClientEvent('chatMessage', source, "[HITMAN INFO]", { 255, 255, 0 }, "Your Hitman Statistics:")
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Reputation: %d | Contracts Completed: %d"):format(data.reputation, data.contractsCompleted))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Contracts Failed: %d | Total Earnings: $%d"):format(data.contractsFailed, data.totalEarnings))
end, false)

-- Turf war commands (already implemented in turf_wars.lua)
-- /captureturf, /turfinfo, /turfs
