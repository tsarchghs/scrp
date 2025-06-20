-- Racing System for SC:RP FiveM

Races = {}
ActiveRaces = {}
RaceCheckpoints = {}

-- Initialize racing tables
function initializeRacingTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `races` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `CreatedBy` int(11) NOT NULL,
            `StartX` float NOT NULL,
            `StartY` float NOT NULL,
            `StartZ` float NOT NULL,
            `Laps` int(2) DEFAULT 1,
            `BuyIn` int(11) DEFAULT 0,
            `MaxParticipants` int(2) DEFAULT 8,
            `VehicleClass` int(2) DEFAULT -1,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `race_checkpoints` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `RaceID` int(11) NOT NULL,
            `CheckpointOrder` int(3) NOT NULL,
            `X` float NOT NULL,
            `Y` float NOT NULL,
            `Z` float NOT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`RaceID`) REFERENCES `races`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `race_results` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `RaceID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `Position` int(2) NOT NULL,
            `FinishTime` float NOT NULL,
            `Winnings` int(11) DEFAULT 0,
            `RaceDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`RaceID`) REFERENCES `races`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `race_bets` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `RaceInstanceID` varchar(32) NOT NULL,
            `BettorID` int(11) NOT NULL,
            `BetOnID` int(11) NOT NULL,
            `BetAmount` int(11) NOT NULL,
            `Payout` int(11) DEFAULT 0,
            `Won` int(1) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Load races from database
function loadRaces()
    local query = [[
        SELECT * FROM `races`
    ]]

    MySQL.query(query, {}, function(rows)
        Races = {}
        for i = 1, #rows do
            local race = rows[i]
            Races[race.ID] = {
                ID = race.ID,
                Name = race.Name,
                CreatedBy = race.CreatedBy,
                Start = {x = race.StartX, y = race.StartY, z = race.StartZ},
                Laps = race.Laps,
                BuyIn = race.BuyIn,
                MaxParticipants = race.MaxParticipants,
                VehicleClass = race.VehicleClass,
                Checkpoints = {}
            }
            
            -- Load checkpoints for this race
            loadRaceCheckpoints(race.ID)
        end
        print(("[SC:RP] Loaded %d races"):format(#rows))
    end)
end

-- Load race checkpoints
function loadRaceCheckpoints(raceId)
    local query = [[
        SELECT * FROM `race_checkpoints` WHERE `RaceID` = @raceId ORDER BY `CheckpointOrder`
    ]]

    MySQL.query(query, {
        ['@raceId'] = raceId
    }, function(rows)
        if Races[raceId] then
            Races[raceId].Checkpoints = {}
            for i = 1, #rows do
                local checkpoint = rows[i]
                table.insert(Races[raceId].Checkpoints, {
                    order = checkpoint.CheckpointOrder,
                    x = checkpoint.X,
                    y = checkpoint.Y,
                    z = checkpoint.Z
                })
            end
        end
    end)
end

-- Create a new race
function createRace(source, name, laps, buyIn, maxParticipants, vehicleClass)
    if not PlayerData[source] then return false end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    local query = [[
        INSERT INTO `races` (`Name`, `CreatedBy`, `StartX`, `StartY`, `StartZ`, `Laps`, `BuyIn`, `MaxParticipants`, `VehicleClass`)
        VALUES (@name, @createdBy, @startX, @startY, @startZ, @laps, @buyIn, @maxParticipants, @vehicleClass)
    ]]

    MySQL.query(query, {
        ['@name'] = name,
        ['@createdBy'] = PlayerData[source].CharacterID,
        ['@startX'] = coords.x,
        ['@startY'] = coords.y,
        ['@startZ'] = coords.z,
        ['@laps'] = laps,
        ['@buyIn'] = buyIn,
        ['@maxParticipants'] = maxParticipants,
        ['@vehicleClass'] = vehicleClass
    }, function(rows, affected)
        if affected > 0 then
            local raceId = MySQL.insertId
            TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
                ("Race '%s' created with ID %d. Use /addcheckpoint %d to add checkpoints."):format(name, raceId, raceId))
            
            -- Reload races
            loadRaces()
        end
    end)
end

-- Add checkpoint to race
function addRaceCheckpoint(source, raceId)
    if not PlayerData[source] or not Races[raceId] then return false end
    
    -- Check if player created this race
    if Races[raceId].CreatedBy ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "You can only add checkpoints to races you created!")
        return false
    end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local checkpointOrder = #Races[raceId].Checkpoints + 1
    
    local query = [[
        INSERT INTO `race_checkpoints` (`RaceID`, `CheckpointOrder`, `X`, `Y`, `Z`)
        VALUES (@raceId, @checkpointOrder, @x, @y, @z)
    ]]

    MySQL.query(query, {
        ['@raceId'] = raceId,
        ['@checkpointOrder'] = checkpointOrder,
        ['@x'] = coords.x,
        ['@y'] = coords.y,
        ['@z'] = coords.z
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
                ("Checkpoint %d added to race %s"):format(checkpointOrder, Races[raceId].Name))
            
            -- Reload race checkpoints
            loadRaceCheckpoints(raceId)
        end
    end)
end

-- Start a race
function startRace(source, raceId)
    if not PlayerData[source] or not Races[raceId] then return false end
    if ActiveRaces[raceId] then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "This race is already active!")
        return false
    end
    
    local race = Races[raceId]
    if #race.Checkpoints < 2 then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "Race needs at least 2 checkpoints!")
        return false
    end
    
    -- Create race instance
    local raceInstanceId = "race_" .. raceId .. "_" .. os.time()
    ActiveRaces[raceId] = {
        instanceId = raceInstanceId,
        raceId = raceId,
        participants = {},
        startTime = 0,
        status = "waiting", -- waiting, countdown, active, finished
        countdownTime = 30,
        results = {},
        bets = {}
    }
    
    -- Add race creator as first participant
    joinRace(source, raceId)
    
    -- Announce race
    TriggerClientEvent('chatMessage', -1, "[RACING]", { 255, 255, 0 }, 
        ("Race '%s' is starting! Buy-in: $%d. Use /joinrace %d to participate."):format(race.Name, race.BuyIn, raceId))
    
    -- Start countdown timer
    CreateThread(function()
        local activeRace = ActiveRaces[raceId]
        if not activeRace then return end
        
        activeRace.status = "countdown"
        
        for countdown = activeRace.countdownTime, 1, -1 do
            Wait(1000)
            
            if not ActiveRaces[raceId] then break end
            
            -- Notify participants
            for participantId, _ in pairs(activeRace.participants) do
                TriggerClientEvent('chatMessage', participantId, "[RACING]", { 255, 255, 0 }, 
                    ("Race starts in %d seconds"):format(countdown))
            end
            
            if countdown <= 5 then
                -- Send countdown to participants
                for participantId, _ in pairs(activeRace.participants) do
                    TriggerClientEvent('scrp:raceCountdown', participantId, countdown)
                end
            end
        end
        
        -- Start race
        if ActiveRaces[raceId] then
            beginRace(raceId)
        end
    end)
    
    return true
end

-- Join a race
function joinRace(source, raceId)
    if not PlayerData[source] or not Races[raceId] or not ActiveRaces[raceId] then return false end
    
    local race = Races[raceId]
    local activeRace = ActiveRaces[raceId]
    
    if activeRace.status ~= "waiting" and activeRace.status ~= "countdown" then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "Race has already started!")
        return false
    end
    
    if activeRace.participants[source] then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "You are already in this race!")
        return false
    end
    
    if #activeRace.participants >= race.MaxParticipants then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "Race is full!")
        return false
    end
    
    -- Check buy-in
    if race.BuyIn > 0 and PlayerData[source].Money < race.BuyIn then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
            ("You need $%d to join this race!"):format(race.BuyIn))
        return false
    end
    
    -- Check if player is in a vehicle
    local ped = GetPlayerPed(source)
    if not IsPedInAnyVehicle(ped, false) then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "You must be in a vehicle to join a race!")
        return false
    end
    
    -- Check vehicle class if specified
    if race.VehicleClass >= 0 then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleClass = GetVehicleClass(vehicle)
        if vehicleClass ~= race.VehicleClass then
            TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, 
                ("This race requires vehicle class %d!"):format(race.VehicleClass))
            return false
        end
    end
    
    -- Deduct buy-in
    if race.BuyIn > 0 then
        PlayerData[source].Money = PlayerData[source].Money - race.BuyIn
    end
    
    -- Add participant
    activeRace.participants[source] = {
        characterId = PlayerData[source].CharacterID,
        name = PlayerData[source].Name,
        currentCheckpoint = 0,
        currentLap = 1,
        startTime = 0,
        finishTime = 0,
        position = 0,
        finished = false
    }
    
    TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
        ("You joined race '%s'! Participants: %d/%d"):format(race.Name, #activeRace.participants, race.MaxParticipants))
    
    -- Notify other participants
    for participantId, participant in pairs(activeRace.participants) do
        if participantId ~= source then
            TriggerClientEvent('chatMessage', participantId, "[RACING]", { 255, 255, 0 }, 
                ("%s joined the race!"):format(PlayerData[source].Name))
        end
    end
    
    return true
end

-- Begin race
function beginRace(raceId)
    local activeRace = ActiveRaces[raceId]
    local race = Races[raceId]
    
    if not activeRace or not race then return end
    
    activeRace.status = "active"
    activeRace.startTime = os.time()
    
    -- Initialize participants
    for participantId, participant in pairs(activeRace.participants) do
        participant.startTime = os.time()
        participant.currentCheckpoint = 1
        participant.currentLap = 1
        
        -- Send race data to participant
        TriggerClientEvent('scrp:startRace', participantId, {
            raceId = raceId,
            checkpoints = race.Checkpoints,
            laps = race.Laps
        })
        
        TriggerClientEvent('chatMessage', participantId, "[RACING]", { 0, 255, 0 }, "Race started! GO GO GO!")
    end
    
    -- Start race monitoring thread
    CreateThread(function()
        while ActiveRaces[raceId] and ActiveRaces[raceId].status == "active" do
            Wait(1000)
            
            local finishedCount = 0
            for participantId, participant in pairs(activeRace.participants) do
                if participant.finished then
                    finishedCount = finishedCount + 1
                end
            end
            
            -- Check if all participants finished or race timeout (30 minutes)
            if finishedCount == #activeRace.participants or (os.time() - activeRace.startTime) > 1800 then
                finishRace(raceId)
                break
            end
        end
    end)
end

-- Handle checkpoint reached
function handleCheckpointReached(source, raceId, checkpointIndex)
    if not ActiveRaces[raceId] or not ActiveRaces[raceId].participants[source] then return end
    
    local activeRace = ActiveRaces[raceId]
    local race = Races[raceId]
    local participant = activeRace.participants[source]
    
    if participant.finished then return end
    
    -- Check if this is the correct next checkpoint
    if checkpointIndex ~= participant.currentCheckpoint then return end
    
    participant.currentCheckpoint = participant.currentCheckpoint + 1
    
    -- Check if completed a lap
    if participant.currentCheckpoint > #race.Checkpoints then
        participant.currentLap = participant.currentLap + 1
        participant.currentCheckpoint = 1
        
        -- Check if finished all laps
        if participant.currentLap > race.Laps then
            finishParticipant(source, raceId)
            return
        else
            TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 255, 0 }, 
                ("Lap %d/%d completed!"):format(participant.currentLap - 1, race.Laps))
        end
    end
    
    -- Send next checkpoint
    TriggerClientEvent('scrp:updateRaceCheckpoint', source, participant.currentCheckpoint, participant.currentLap)
end

-- Finish participant
function finishParticipant(source, raceId)
    if not ActiveRaces[raceId] or not ActiveRaces[raceId].participants[source] then return end
    
    local activeRace = ActiveRaces[raceId]
    local participant = activeRace.participants[source]
    
    participant.finished = true
    participant.finishTime = os.time() - participant.startTime
    participant.position = #activeRace.results + 1
    
    table.insert(activeRace.results, {
        source = source,
        characterId = participant.characterId,
        name = participant.name,
        position = participant.position,
        finishTime = participant.finishTime
    })
    
    TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
        ("You finished in position %d! Time: %.2f seconds"):format(participant.position, participant.finishTime))
    
    -- Notify other participants
    for participantId, _ in pairs(activeRace.participants) do
        if participantId ~= source then
            TriggerClientEvent('chatMessage', participantId, "[RACING]", { 255, 255, 0 }, 
                ("%s finished in position %d!"):format(participant.name, participant.position))
        end
    end
    
    TriggerClientEvent('scrp:raceFinished', source)
end

-- Finish race
function finishRace(raceId)
    local activeRace = ActiveRaces[raceId]
    local race = Races[raceId]
    
    if not activeRace or not race then return end
    
    activeRace.status = "finished"
    
    -- Calculate prize pool
    local prizePool = #activeRace.participants * race.BuyIn
    local prizes = {
        [1] = math.floor(prizePool * 0.5), -- 50% for 1st
        [2] = math.floor(prizePool * 0.3), -- 30% for 2nd
        [3] = math.floor(prizePool * 0.2)  -- 20% for 3rd
    }
    
    -- Award prizes and save results
    for _, result in ipairs(activeRace.results) do
        local prize = prizes[result.position] or 0
        
        if prize > 0 and PlayerData[result.source] then
            PlayerData[result.source].Money = PlayerData[result.source].Money + prize
            TriggerClientEvent('chatMessage', result.source, "[RACING]", { 0, 255, 0 }, 
                ("You won $%d for finishing %d%s!"):format(prize, result.position, 
                result.position == 1 and "st" or (result.position == 2 and "nd" or (result.position == 3 and "rd" or "th"))))
        end
        
        -- Save result to database
        MySQL.query([[
            INSERT INTO `race_results` (`RaceID`, `CharacterID`, `Position`, `FinishTime`, `Winnings`)
            VALUES (@raceId, @characterId, @position, @finishTime, @winnings)
        ]], {
            ['@raceId'] = raceId,
            ['@characterId'] = result.characterId,
            ['@position'] = result.position,
            ['@finishTime'] = result.finishTime,
            ['@winnings'] = prize
        })
    end
    
    -- Process bets
    processBets(activeRace.instanceId, activeRace.results)
    
    -- Announce results
    TriggerClientEvent('chatMessage', -1, "[RACING]", { 255, 255, 0 }, 
        ("Race '%s' finished!"):format(race.Name))
    
    if #activeRace.results > 0 then
        local winner = activeRace.results[1]
        TriggerClientEvent('chatMessage', -1, "[RACING]", { 0, 255, 0 }, 
            ("Winner: %s (%.2f seconds)"):format(winner.name, winner.finishTime))
    end
    
    -- Clean up
    ActiveRaces[raceId] = nil
end

-- Place bet on race participant
function placeBet(source, raceId, targetCharacterId, amount)
    if not PlayerData[source] or not ActiveRaces[raceId] then return false end
    
    local activeRace = ActiveRaces[raceId]
    
    if activeRace.status ~= "waiting" and activeRace.status ~= "countdown" then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "Betting is closed!")
        return false
    end
    
    if PlayerData[source].Money < amount then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    -- Check if target is in the race
    local targetInRace = false
    local targetName = "Unknown"
    for participantId, participant in pairs(activeRace.participants) do
        if participant.characterId == targetCharacterId then
            targetInRace = true
            targetName = participant.name
            break
        end
    end
    
    if not targetInRace then
        TriggerClientEvent('chatMessage', source, "[RACING]", { 255, 0, 0 }, "That player is not in this race!")
        return false
    end
    
    -- Deduct money
    PlayerData[source].Money = PlayerData[source].Money - amount
    
    -- Record bet
    MySQL.query([[
        INSERT INTO `race_bets` (`RaceInstanceID`, `BettorID`, `BetOnID`, `BetAmount`)
        VALUES (@raceInstanceId, @bettorId, @betOnId, @betAmount)
    ]], {
        ['@raceInstanceId'] = activeRace.instanceId,
        ['@bettorId'] = PlayerData[source].CharacterID,
        ['@betOnId'] = targetCharacterId,
        ['@betAmount'] = amount
    })
    
    TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
        ("You bet $%d on %s to win!"):format(amount, targetName))
    
    return true
end

-- Process bets after race
function processBets(raceInstanceId, results)
    if #results == 0 then return end
    
    local winnerId = results[1].characterId
    
    -- Get all bets for this race
    local query = [[
        SELECT * FROM `race_bets` WHERE `RaceInstanceID` = @raceInstanceId
    ]]

    MySQL.query(query, {
        ['@raceInstanceId'] = raceInstanceId
    }, function(rows)
        local totalBets = 0
        local winningBets = 0
        
        -- Calculate totals
        for i = 1, #rows do
            local bet = rows[i]
            totalBets = totalBets + bet.BetAmount
            if bet.BetOnID == winnerId then
                winningBets = winningBets + bet.BetAmount
            end
        end
        
        -- Calculate odds and payouts
        for i = 1, #rows do
            local bet = rows[i]
            local payout = 0
            local won = 0
            
            if bet.BetOnID == winnerId and winningBets > 0 then
                -- Winner gets their bet back plus share of losing bets
                local share = bet.BetAmount / winningBets
                payout = bet.BetAmount + math.floor((totalBets - winningBets) * share)
                won = 1
                
                -- Pay out to player if online
                for source, data in pairs(PlayerData) do
                    if data.CharacterID == bet.BettorID then
                        PlayerData[source].Money = PlayerData[source].Money + payout
                        TriggerClientEvent('chatMessage', source, "[RACING]", { 0, 255, 0 }, 
                            ("Your bet won! You received $%d!"):format(payout))
                        break
                    end
                end
            end
            
            -- Update bet record
            MySQL.query([[
                UPDATE `race_bets` SET `Payout` = @payout, `Won` = @won
                WHERE `RaceInstanceID` = @raceInstanceId AND `BettorID` = @bettorId AND `BetOnID` = @betOnId
            ]], {
                ['@payout'] = payout,
                ['@won'] = won,
                ['@raceInstanceId'] = raceInstanceId,
                ['@bettorId'] = bet.BettorID,
                ['@betOnId'] = bet.BetOnID
            })
        end
    end)
end
