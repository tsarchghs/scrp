-- Advanced Turf War System for SC:RP FiveM
-- mysql-async version 3.3.2 compatible with FiveM artifact 15859

TurfWars = {
    captureTime = 5, -- 5 seconds to capture
    protectionTime = 900, -- 15 minutes (900 seconds) to protect
    zones = {
        [1] = {
            name = "Grove Street Territory",
            points = {
                {x = 2480.0, y = -1670.0},
                {x = 2550.0, y = -1670.0},
                {x = 2550.0, y = -1600.0},
                {x = 2480.0, y = -1600.0}
            },
            center = {x = 2515.0, y = -1635.0, z = 13.5},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            income = 2000,
            color = {r = 0, g = 255, b = 0, a = 100} -- Green
        },
        [2] = {
            name = "Ballas Hood",
            points = {
                {x = 2000.0, y = -1400.0},
                {x = 2100.0, y = -1400.0},
                {x = 2100.0, y = -1300.0},
                {x = 2000.0, y = -1300.0}
            },
            center = {x = 2050.0, y = -1350.0, z = 13.5},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            income = 1800,
            color = {r = 128, g = 0, b = 128, a = 100} -- Purple
        },
        [3] = {
            name = "Vagos Territory",
            points = {
                {x = 2700.0, y = -1900.0},
                {x = 2800.0, y = -1900.0},
                {x = 2800.0, y = -1800.0},
                {x = 2700.0, y = -1800.0}
            },
            center = {x = 2750.0, y = -1850.0, z = 13.5},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            income = 1500,
            color = {r = 255, g = 255, b = 0, a = 100} -- Yellow
        },
        [4] = {
            name = "Aztecas Barrio",
            points = {
                {x = 1800.0, y = -1700.0},
                {x = 1900.0, y = -1700.0},
                {x = 1900.0, y = -1600.0},
                {x = 1800.0, y = -1600.0}
            },
            center = {x = 1850.0, y = -1650.0, z = 13.5},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            income = 1200,
            color = {r = 0, g = 191, b = 255, a = 100} -- Light Blue
        },
        [5] = {
            name = "Families Block",
            points = {
                {x = 2300.0, y = -1500.0},
                {x = 2400.0, y = -1500.0},
                {x = 2400.0, y = -1400.0},
                {x = 2300.0, y = -1400.0}
            },
            center = {x = 2350.0, y = -1450.0, z = 13.5},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            income = 1000,
            color = {r = 0, g = 128, b = 0, a = 100} -- Dark Green
        }
    },
    activeCaptureThreads = {}
}

-- Initialize turf war tables
function initializeTurfWarTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `turf_zones` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `ControlledBy` int(11) DEFAULT 0,
            `CaptureTime` datetime DEFAULT NULL,
            `Income` int(11) DEFAULT 1000,
            `CenterX` float NOT NULL,
            `CenterY` float NOT NULL,
            `CenterZ` float NOT NULL,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `turf_captures` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ZoneID` int(11) NOT NULL,
            `AttackingFaction` int(11) NOT NULL,
            `DefendingFaction` int(11) DEFAULT 0,
            `CaptureStartTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `CaptureEndTime` datetime DEFAULT NULL,
            `Success` int(1) DEFAULT 0,
            `AttackersPresent` int(11) DEFAULT 0,
            `DefendersPresent` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ZoneID`) REFERENCES `turf_zones`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `turf_battles` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ZoneID` int(11) NOT NULL,
            `KillerFaction` int(11) NOT NULL,
            `VictimFaction` int(11) NOT NULL,
            `KillerID` int(11) NOT NULL,
            `VictimID` int(11) NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Insert default zones
    for zoneId, zone in pairs(TurfWars.zones) do
        MySQL.query([[
            INSERT IGNORE INTO `turf_zones` (`ID`, `Name`, `CenterX`, `CenterY`, `CenterZ`, `Income`)
            VALUES (@zoneId, @name, @centerX, @centerY, @centerZ, @income)
        ]], {
            ['@zoneId'] = zoneId,
            ['@name'] = zone.name,
            ['@centerX'] = zone.center.x,
            ['@centerY'] = zone.center.y,
            ['@centerZ'] = zone.center.z,
            ['@income'] = zone.income
        })
    end
end

-- Load turf data from database
function loadTurfData()
    local query = [[
        SELECT * FROM `turf_zones`
    ]]

    MySQL.query(query, {}, function(rows)
        for i = 1, #rows do
            local zone = rows[i]
            if TurfWars.zones[zone.ID] then
                TurfWars.zones[zone.ID].controlledBy = zone.ControlledBy
                TurfWars.zones[zone.ID].income = zone.Income
            end
        end
        
        -- Send turf data to all clients
        TriggerClientEvent('scrp:updateTurfZones', -1, TurfWars.zones)
        print(("[SC:RP] Loaded %d turf zones"):format(#rows))
    end)
end

-- Check if player is in a turf zone
function getPlayerTurfZone(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    for zoneId, zone in pairs(TurfWars.zones) do
        if isPointInPolygon(coords.x, coords.y, zone.points) then
            return zoneId
        end
    end
    
    return nil
end

-- Check if point is inside polygon
function isPointInPolygon(x, y, polygon)
    local inside = false
    local j = #polygon
    
    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

-- Start turf capture
function startTurfCapture(source, zoneId)
    if not PlayerData[source] or not TurfWars.zones[zoneId] then return false end
    if PlayerData[source].FactionID == 0 then
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, "You must be in a gang to capture turf!")
        return false
    end
    
    local zone = TurfWars.zones[zoneId]
    local attackingFaction = PlayerData[source].FactionID
    
    -- Check if already controlled by same faction
    if zone.controlledBy == attackingFaction then
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, "Your gang already controls this turf!")
        return false
    end
    
    -- Check if already being captured
    if zone.isBeingCaptured then
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, "This turf is already being captured!")
        return false
    end
    
    -- Check if in protection period
    if zone.isProtected and (os.time() - zone.protectionStartTime) < TurfWars.protectionTime then
        local timeLeft = TurfWars.protectionTime - (os.time() - zone.protectionStartTime)
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, 
            ("This turf is protected for %d more seconds!"):format(timeLeft))
        return false
    end
    
    -- Start capture process
    zone.isBeingCaptured = true
    zone.contestedBy = attackingFaction
    zone.captureStartTime = os.time()
    zone.captureProgress = 0
    zone.isProtected = false
    
    -- Log capture attempt
    MySQL.query([[
        INSERT INTO `turf_captures` (`ZoneID`, `AttackingFaction`, `DefendingFaction`)
        VALUES (@zoneId, @attackingFaction, @defendingFaction)
    ]], {
        ['@zoneId'] = zoneId,
        ['@attackingFaction'] = attackingFaction,
        ['@defendingFaction'] = zone.controlledBy
    })
    
    -- Notify all players
    local attackingFactionName = Factions[attackingFaction] and Factions[attackingFaction].Name or "Unknown Gang"
    TriggerClientEvent('chatMessage', -1, "[TURF WAR]", { 255, 0, 0 }, 
        ("%s is attempting to capture %s!"):format(attackingFactionName, zone.name))
    
    -- Start capture thread
    startCaptureThread(zoneId)
    
    -- Update clients
    TriggerClientEvent('scrp:updateTurfZones', -1, TurfWars.zones)
    
    return true
end

-- Start capture thread
function startCaptureThread(zoneId)
    if TurfWars.activeCaptureThreads[zoneId] then return end
    
    TurfWars.activeCaptureThreads[zoneId] = true
    
    CreateThread(function()
        local zone = TurfWars.zones[zoneId]
        local captureStartTime = os.time()
        
        while zone.isBeingCaptured and (os.time() - captureStartTime) < TurfWars.captureTime do
            Wait(100)
            
            -- Check if attackers are still present
            local attackersPresent = 0
            local defendersPresent = 0
            
            for source, data in pairs(PlayerData) do
                local playerZone = getPlayerTurfZone(source)
                if playerZone == zoneId then
                    if data.FactionID == zone.contestedBy then
                        attackersPresent = attackersPresent + 1
                    elseif data.FactionID == zone.controlledBy then
                        defendersPresent = defendersPresent + 1
                    end
                end
            end
            
            -- If no attackers present, cancel capture
            if attackersPresent == 0 then
                cancelTurfCapture(zoneId, "No attackers present")
                break
            end
            
            -- Update progress
            zone.captureProgress = ((os.time() - captureStartTime) / TurfWars.captureTime) * 100
            
            -- Send progress update to clients in zone
            for source, data in pairs(PlayerData) do
                local playerZone = getPlayerTurfZone(source)
                if playerZone == zoneId then
                    TriggerClientEvent('scrp:updateCaptureProgress', source, zone.captureProgress)
                end
            end
        end
        
        -- Check if capture was successful
        if zone.isBeingCaptured and (os.time() - captureStartTime) >= TurfWars.captureTime then
            completeTurfCapture(zoneId)
        end
        
        TurfWars.activeCaptureThreads[zoneId] = nil
    end)
end

-- Complete turf capture
function completeTurfCapture(zoneId)
    local zone = TurfWars.zones[zoneId]
    local oldController = zone.controlledBy
    local newController = zone.contestedBy
    
    -- Update zone control
    zone.controlledBy = newController
    zone.isBeingCaptured = false
    zone.contestedBy = 0
    zone.isProtected = true
    zone.protectionStartTime = os.time()
    zone.captureProgress = 0
    
    -- Update database
    MySQL.query([[
        UPDATE `turf_zones` SET `ControlledBy` = @newController, `CaptureTime` = NOW()
        WHERE `ID` = @zoneId
    ]], {
        ['@newController'] = newController,
        ['@zoneId'] = zoneId
    })
    
    -- Update capture log
    MySQL.query([[
        UPDATE `turf_captures` SET `CaptureEndTime` = NOW(), `Success` = 1
        WHERE `ZoneID` = @zoneId AND `AttackingFaction` = @attackingFaction AND `CaptureEndTime` IS NULL
    ]], {
        ['@zoneId'] = zoneId,
        ['@attackingFaction'] = newController
    })
    
    -- Notify all players
    local newFactionName = Factions[newController] and Factions[newController].Name or "Unknown Gang"
    TriggerClientEvent('chatMessage', -1, "[TURF WAR]", { 0, 255, 0 }, 
        ("%s has captured %s! Protection period: 15 minutes"):format(newFactionName, zone.name))
    
    -- Start protection thread
    startProtectionThread(zoneId)
    
    -- Update clients
    TriggerClientEvent('scrp:updateTurfZones', -1, TurfWars.zones)
    TriggerClientEvent('scrp:turfCaptured', -1, zoneId, newController, oldController)
end

-- Cancel turf capture
function cancelTurfCapture(zoneId, reason)
    local zone = TurfWars.zones[zoneId]
    
    zone.isBeingCaptured = false
    zone.contestedBy = 0
    zone.captureProgress = 0
    
    -- Update capture log
    MySQL.query([[
        UPDATE `turf_captures` SET `CaptureEndTime` = NOW(), `Success` = 0
        WHERE `ZoneID` = @zoneId AND `CaptureEndTime` IS NULL
    ]], {
        ['@zoneId'] = zoneId
    })
    
    -- Notify players
    TriggerClientEvent('chatMessage', -1, "[TURF WAR]", { 255, 255, 0 }, 
        ("Turf capture of %s was cancelled: %s"):format(zone.name, reason))
    
    -- Update clients
    TriggerClientEvent('scrp:updateTurfZones', -1, TurfWars.zones)
end

-- Start protection thread
function startProtectionThread(zoneId)
    CreateThread(function()
        Wait(TurfWars.protectionTime * 1000) -- 15 minutes
        
        local zone = TurfWars.zones[zoneId]
        zone.isProtected = false
        
        -- Notify faction members
        local factionName = Factions[zone.controlledBy] and Factions[zone.controlledBy].Name or "Unknown Gang"
        for source, data in pairs(PlayerData) do
            if data.FactionID == zone.controlledBy then
                TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 255, 0 }, 
                    ("Your turf %s is no longer protected!"):format(zone.name))
            end
        end
        
        -- Update clients
        TriggerClientEvent('scrp:updateTurfZones', -1, TurfWars.zones)
    end)
end

-- Handle player death in turf war
function handleTurfWarDeath(killerId, victimId)
    if not PlayerData[killerId] or not PlayerData[victimId] then return end
    
    local killerZone = getPlayerTurfZone(killerId)
    local victimZone = getPlayerTurfZone(victimId)
    
    if killerZone and victimZone and killerZone == victimZone then
        local zone = TurfWars.zones[killerZone]
        
        -- Only count if it's during a turf war
        if zone.isBeingCaptured or zone.isProtected then
            local killerFaction = PlayerData[killerId].FactionID
            local victimFaction = PlayerData[victimId].FactionID
            
            if killerFaction ~= victimFaction and killerFaction > 0 and victimFaction > 0 then
                -- Log the battle
                MySQL.query([[
                    INSERT INTO `turf_battles` (`ZoneID`, `KillerFaction`, `VictimFaction`, `KillerID`, `VictimID`)
                    VALUES (@zoneId, @killerFaction, @victimFaction, @killerId, @victimId)
                ]], {
                    ['@zoneId'] = killerZone,
                    ['@killerFaction'] = killerFaction,
                    ['@victimFaction'] = victimFaction,
                    ['@killerId'] = PlayerData[killerId].CharacterID,
                    ['@victimId'] = PlayerData[victimId].CharacterID
                })
                
                -- Award experience for turf war kill
                addSkillExperience(killerId, "shooting", 25)
                
                -- Notify players
                TriggerClientEvent('chatMessage', killerId, "[TURF WAR]", { 0, 255, 0 }, 
                    ("You killed an enemy gang member in %s!"):format(zone.name))
            end
        end
    end
end

-- Turf income system
CreateThread(function()
    while true do
        Wait(3600000) -- 1 hour
        
        for zoneId, zone in pairs(TurfWars.zones) do
            if zone.controlledBy > 0 and Factions[zone.controlledBy] then
                -- Add income to faction budget
                Factions[zone.controlledBy].Budget = Factions[zone.controlledBy].Budget + zone.income
                
                -- Update database
                MySQL.query([[
                    UPDATE `factions` SET `Budget` = @budget WHERE `ID` = @factionId
                ]], {
                    ['@budget'] = Factions[zone.controlledBy].Budget,
                    ['@factionId'] = zone.controlledBy
                })
                
                -- Notify faction members
                for source, data in pairs(PlayerData) do
                    if data.FactionID == zone.controlledBy then
                        TriggerClientEvent('chatMessage', source, "[TURF]", { 0, 255, 0 }, 
                            ("Your gang earned $%d from %s"):format(zone.income, zone.name))
                    end
                end
            end
        end
    end
end)

-- Command to attempt turf capture
RegisterCommand('captureturf', function(source, args, rawCommand)
    local playerZone = getPlayerTurfZone(source)
    if not playerZone then
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, "You are not in a turf zone!")
        return
    end
    
    startTurfCapture(source, playerZone)
end, false)

-- Command to view turf information
RegisterCommand('turfinfo', function(source, args, rawCommand)
    local playerZone = getPlayerTurfZone(source)
    if not playerZone then
        TriggerClientEvent('chatMessage', source, "[TURF]", { 255, 0, 0 }, "You are not in a turf zone!")
        return
    end
    
    local zone = TurfWars.zones[playerZone]
    local controllerName = "Unclaimed"
    if zone.controlledBy > 0 and Factions[zone.controlledBy] then
        controllerName = Factions[zone.controlledBy].Name
    end
    
    TriggerClientEvent('chatMessage', source, "[TURF INFO]", { 255, 255, 0 }, 
        ("Zone: %s"):format(zone.name))
    TriggerClientEvent('chatMessage', source, "[TURF INFO]", { 255, 255, 0 }, 
        ("Controlled by: %s"):format(controllerName))
    TriggerClientEvent('chatMessage', source, "[TURF INFO]", { 255, 255, 0 }, 
        ("Income: $%d/hour"):format(zone.income))
    
    if zone.isBeingCaptured then
        local contestingFactionName = Factions[zone.contestedBy] and Factions[zone.contestedBy].Name or "Unknown Gang"
        TriggerClientEvent('chatMessage', source, "[TURF INFO]", { 255, 0, 0 }, 
            ("Being captured by: %s (%.1f%%)"):format(contestingFactionName, zone.captureProgress))
    elseif zone.isProtected then
        local timeLeft = TurfWars.protectionTime - (os.time() - zone.protectionStartTime)
        if timeLeft > 0 then
            TriggerClientEvent('chatMessage', source, "[TURF INFO]", { 0, 255, 0 }, 
                ("Protected for: %d seconds"):format(timeLeft))
        end
    end
end, false)

-- Command to list all turfs
RegisterCommand('turfs', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[TURF ZONES]", { 255, 255, 0 }, "Gang Territory Status:")
    
    for zoneId, zone in pairs(TurfWars.zones) do
        local controllerName = "Unclaimed"
        local status = "Available"
        
        if zone.controlledBy > 0 and Factions[zone.controlledBy] then
            controllerName = Factions[zone.controlledBy].Name
            if zone.isProtected then
                local timeLeft = TurfWars.protectionTime - (os.time() - zone.protectionStartTime)
                if timeLeft > 0 then
                    status = ("Protected (%ds)"):format(timeLeft)
                else
                    status = "Vulnerable"
                end
            else
                status = "Vulnerable"
            end
        end
        
        if zone.isBeingCaptured then
            local contestingFactionName = Factions[zone.contestedBy] and Factions[zone.contestedBy].Name or "Unknown Gang"
            status = ("Being captured by %s"):format(contestingFactionName)
        end
        
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s - %s - %s - $%d/hr"):format(zoneId, zone.name, controllerName, status, zone.income))
    end
end, false)
