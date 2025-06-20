-- Advanced Prison System for SC:RP FiveM

Prison = {
    location = {x = 1679.04, y = 2513.71, z = 45.56},
    cells = {
        {x = 1661.04, y = 2524.71, z = 45.56},
        {x = 1665.04, y = 2524.71, z = 45.56},
        {x = 1669.04, y = 2524.71, z = 45.56},
        {x = 1673.04, y = 2524.71, z = 45.56}
    },
    jobs = {
        ["laundry"] = {name = "Laundry Duty", pay = 25, location = {x = 1629.55, y = 2564.63, z = 45.56}},
        ["kitchen"] = {name = "Kitchen Work", pay = 30, location = {x = 1634.90, y = 2571.58, z = 45.56}},
        ["cleaning"] = {name = "Cleaning", pay = 20, location = {x = 1692.02, y = 2566.05, z = 45.56}},
        ["library"] = {name = "Library Assistant", pay = 35, location = {x = 1667.35, y = 2407.78, z = 45.56}}
    }
}

PrisonData = {}

-- Initialize prison tables
function initializePrisonTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `prison_sentences` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `Crime` varchar(128) NOT NULL,
            `SentenceTime` int(11) NOT NULL,
            `RemainingTime` int(11) NOT NULL,
            `JailedBy` int(11) NOT NULL,
            `JailDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ReleaseDate` datetime DEFAULT NULL,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `prison_reputation` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `Reputation` int(11) DEFAULT 0,
            `Respect` int(11) DEFAULT 0,
            `Fights` int(11) DEFAULT 0,
            `JobsCompleted` int(11) DEFAULT 0,
            `TimeServed` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `CharacterID` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `prison_jobs` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `JobType` varchar(32) NOT NULL,
            `CompletedAt` datetime DEFAULT CURRENT_TIMESTAMP,
            `Payment` int(11) NOT NULL,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `prison_fights` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `WinnerID` int(11) NOT NULL,
            `LoserID` int(11) NOT NULL,
            `FightDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ReputationGained` int(11) DEFAULT 10,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Load prison data for character
function loadPrisonData(source, characterId)
    local query = [[
        SELECT * FROM `prison_reputation` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local data = rows[1]
            PrisonData[source] = {
                reputation = data.Reputation,
                respect = data.Respect,
                fights = data.Fights,
                jobsCompleted = data.JobsCompleted,
                timeServed = data.TimeServed
            }
        else
            -- Create new prison record
            MySQL.query([[
                INSERT INTO `prison_reputation` (`CharacterID`) VALUES (@characterId)
            ]], {
                ['@characterId'] = characterId
            })
            
            PrisonData[source] = {
                reputation = 0,
                respect = 0,
                fights = 0,
                jobsCompleted = 0,
                timeServed = 0
            }
        end
    end)
end

-- Jail a player
function jailPlayer(source, targetId, crime, sentenceMinutes, jailedBy)
    if not PlayerData[targetId] then return false end
    
    local characterId = PlayerData[targetId].CharacterID
    local sentenceSeconds = sentenceMinutes * 60
    
    -- Update character jail status
    PlayerData[targetId].Jailed = 1
    PlayerData[targetId].JailTime = sentenceSeconds
    
    -- Insert prison sentence
    MySQL.query([[
        INSERT INTO `prison_sentences` (`CharacterID`, `Crime`, `SentenceTime`, `RemainingTime`, `JailedBy`)
        VALUES (@characterId, @crime, @sentenceTime, @remainingTime, @jailedBy)
    ]], {
        ['@characterId'] = characterId,
        ['@crime'] = crime,
        ['@sentenceTime'] = sentenceSeconds,
        ['@remainingTime'] = sentenceSeconds,
        ['@jailedBy'] = jailedBy
    })
    
    -- Update database
    MySQL.query([[
        UPDATE `characters` SET `Jailed` = 1, `JailTime` = @jailTime WHERE `ID` = @characterId
    ]], {
        ['@jailTime'] = sentenceSeconds,
        ['@characterId'] = characterId
    })
    
    -- Teleport to prison
    local cellIndex = math.random(1, #Prison.cells)
    local cell = Prison.cells[cellIndex]
    TriggerClientEvent('scrp:teleportPlayer', targetId, cell.x, cell.y, cell.z)
    
    -- Remove weapons
    TriggerClientEvent('scrp:removeAllWeapons', targetId)
    
    -- Notify
    TriggerClientEvent('chatMessage', targetId, "[PRISON]", { 255, 0, 0 }, 
        ("You have been sentenced to %d minutes in prison for: %s"):format(sentenceMinutes, crime))
    
    if source then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 0, 255, 0 }, 
            ("You jailed %s for %d minutes"):format(PlayerData[targetId].Name, sentenceMinutes))
    end
    
    -- Start jail timer
    startJailTimer(targetId)
    
    return true
end

-- Start jail timer
function startJailTimer(source)
    CreateThread(function()
        while PlayerData[source] and PlayerData[source].Jailed == 1 and PlayerData[source].JailTime > 0 do
            Wait(1000)
            
            if PlayerData[source] then
                PlayerData[source].JailTime = PlayerData[source].JailTime - 1
                
                -- Update prison reputation time served
                if PrisonData[source] then
                    PrisonData[source].timeServed = PrisonData[source].timeServed + 1
                end
                
                -- Notify every minute
                if PlayerData[source].JailTime % 60 == 0 then
                    local minutesLeft = math.floor(PlayerData[source].JailTime / 60)
                    TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 255, 0 }, 
                        ("Time remaining: %d minutes"):format(minutesLeft))
                end
            end
        end
        
        -- Release player
        if PlayerData[source] and PlayerData[source].Jailed == 1 then
            releasePlayer(source)
        end
    end)
end

-- Release player from prison
function releasePlayer(source)
    if not PlayerData[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    
    -- Update character status
    PlayerData[source].Jailed = 0
    PlayerData[source].JailTime = 0
    
    -- Update database
    MySQL.query([[
        UPDATE `characters` SET `Jailed` = 0, `JailTime` = 0 WHERE `ID` = @characterId
    ]], {
        ['@characterId'] = characterId
    })
    
    -- Update prison sentence
    MySQL.query([[
        UPDATE `prison_sentences` SET `Active` = 0, `ReleaseDate` = NOW()
        WHERE `CharacterID` = @characterId AND `Active` = 1
    ]], {
        ['@characterId'] = characterId
    })
    
    -- Save prison data
    savePrisonData(source)
    
    -- Teleport to prison exit
    TriggerClientEvent('scrp:teleportPlayer', source, 1848.13, 2586.05, 45.67)
    
    TriggerClientEvent('chatMessage', source, "[PRISON]", { 0, 255, 0 }, 
        "You have been released from prison. Stay out of trouble!")
end

-- Save prison data
function savePrisonData(source)
    if not PlayerData[source] or not PrisonData[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    local data = PrisonData[source]
    
    MySQL.query([[
        UPDATE `prison_reputation` SET 
        `Reputation` = @reputation, `Respect` = @respect, `Fights` = @fights,
        `JobsCompleted` = @jobsCompleted, `TimeServed` = @timeServed
        WHERE `CharacterID` = @characterId
    ]], {
        ['@reputation'] = data.reputation,
        ['@respect'] = data.respect,
        ['@fights'] = data.fights,
        ['@jobsCompleted'] = data.jobsCompleted,
        ['@timeServed'] = data.timeServed,
        ['@characterId'] = characterId
    })
end

-- Complete prison job
function completePrisonJob(source, jobType)
    if not PlayerData[source] or PlayerData[source].Jailed ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, "You are not in prison!")
        return false
    end
    
    if not Prison.jobs[jobType] then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, "Invalid job type!")
        return false
    end
    
    local job = Prison.jobs[jobType]
    local characterId = PlayerData[source].CharacterID
    
    -- Check if player is near job location
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local distance = #(coords - vector3(job.location.x, job.location.y, job.location.z))
    
    if distance > 5.0 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, 
            ("You must be near the %s area to work!"):format(job.name))
        return false
    end
    
    -- Add money to player
    PlayerData[source].Money = PlayerData[source].Money + job.pay
    
    -- Update prison data
    if PrisonData[source] then
        PrisonData[source].jobsCompleted = PrisonData[source].jobsCompleted + 1
        PrisonData[source].reputation = PrisonData[source].reputation + 5
    end
    
    -- Log job completion
    MySQL.query([[
        INSERT INTO `prison_jobs` (`CharacterID`, `JobType`, `Payment`)
        VALUES (@characterId, @jobType, @payment)
    ]], {
        ['@characterId'] = characterId,
        ['@jobType'] = jobType,
        ['@payment'] = job.pay
    })
    
    TriggerClientEvent('chatMessage', source, "[PRISON]", { 0, 255, 0 }, 
        ("You completed %s and earned $%d. Reputation +5"):format(job.name, job.pay))
    
    return true
end

-- Start prison fight
function startPrisonFight(source, targetId)
    if not PlayerData[source] or not PlayerData[targetId] then return false end
    if PlayerData[source].Jailed ~= 1 or PlayerData[targetId].Jailed ~= 1 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, "Both players must be in prison!")
        return false
    end
    
    -- Check distance
    local ped1 = GetPlayerPed(source)
    local ped2 = GetPlayerPed(targetId)
    local coords1 = GetEntityCoords(ped1)
    local coords2 = GetEntityCoords(ped2)
    local distance = #(coords1 - coords2)
    
    if distance > 5.0 then
        TriggerClientEvent('chatMessage', source, "[PRISON]", { 255, 0, 0 }, "You are too far from the target!")
        return false
    end
    
    -- Determine winner based on reputation and random factor
    local sourceRep = PrisonData[source] and PrisonData[source].reputation or 0
    local targetRep = PrisonData[targetId] and PrisonData[targetId].reputation or 0
    
    local sourceChance = 50 + (sourceRep - targetRep) * 0.1
    local roll = math.random(1, 100)
    
    local winner, loser
    if roll <= sourceChance then
        winner = source
        loser = targetId
    else
        winner = targetId
        loser = source
    end
    
    -- Update reputation
    if PrisonData[winner] then
        PrisonData[winner].reputation = PrisonData[winner].reputation + 10
        PrisonData[winner].respect = PrisonData[winner].respect + 5
        PrisonData[winner].fights = PrisonData[winner].fights + 1
    end
    
    if PrisonData[loser] then
        PrisonData[loser].reputation = math.max(0, PrisonData[loser].reputation - 5)
        PrisonData[loser].fights = PrisonData[loser].fights + 1
    end
    
    -- Log fight
    MySQL.query([[
        INSERT INTO `prison_fights` (`WinnerID`, `LoserID`, `ReputationGained`)
        VALUES (@winnerId, @loserId, 10)
    ]], {
        ['@winnerId'] = PlayerData[winner].CharacterID,
        ['@loserId'] = PlayerData[loser].CharacterID
    })
    
    -- Notify players
    TriggerClientEvent('chatMessage', winner, "[PRISON]", { 0, 255, 0 }, 
        ("You won the fight! Reputation +10, Respect +5"))
    TriggerClientEvent('chatMessage', loser, "[PRISON]", { 255, 0, 0 }, 
        ("You lost the fight! Reputation -5"))
    
    -- Damage loser
    local loserPed = GetPlayerPed(loser)
    SetEntityHealth(loserPed, GetEntityHealth(loserPed) - 50)
    
    return true
end
