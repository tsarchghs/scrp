-- Enhanced Zone Control System for SC:RP FiveM
-- mysql-async version 3.3.2 compatible with FiveM artifact 15859

EnhancedZones = {
    captureTime = 5, -- 5 seconds to capture
    protectionTime = 900, -- 15 minutes protection
    zones = {
        -- Gang Territories (existing)
        [1] = {
            name = "Grove Street Territory",
            type = "gang_territory",
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
            baseIncome = 2000,
            bonusMultiplier = 1.0,
            activities = {"drug_dealing", "weapon_trading", "protection_racket"},
            requiredMembers = 3,
            color = {r = 0, g = 255, b = 0, a = 100}
        },
        
        -- Business Districts
        [6] = {
            name = "Downtown Business District",
            type = "business_district",
            points = {
                {x = 200.0, y = -800.0},
                {x = 400.0, y = -800.0},
                {x = 400.0, y = -600.0},
                {x = 200.0, y = -600.0}
            },
            center = {x = 300.0, y = -700.0, z = 30.0},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            baseIncome = 5000,
            bonusMultiplier = 1.0,
            activities = {"business_tax", "protection_money", "loan_sharking"},
            requiredMembers = 5,
            color = {r = 0, g = 0, b = 255, a = 100}
        },
        
        [7] = {
            name = "Industrial Port",
            type = "smuggling_zone",
            points = {
                {x = 1000.0, y = -3000.0},
                {x = 1200.0, y = -3000.0},
                {x = 1200.0, y = -2800.0},
                {x = 1000.0, y = -2800.0}
            },
            center = {x = 1100.0, y = -2900.0, z = 5.0},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            baseIncome = 3500,
            bonusMultiplier = 1.0,
            activities = {"weapon_smuggling", "drug_import", "vehicle_theft"},
            requiredMembers = 4,
            color = {r = 255, g = 165, b = 0, a = 100}
        },
        
        [8] = {
            name = "Racing Circuit",
            type = "racing_zone",
            points = {
                {x = -1500.0, y = 1000.0},
                {x = -1300.0, y = 1000.0},
                {x = -1300.0, y = 1200.0},
                {x = -1500.0, y = 1200.0}
            },
            center = {x = -1400.0, y = 1100.0, z = 25.0},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            baseIncome = 2500,
            bonusMultiplier = 1.0,
            activities = {"illegal_racing", "car_theft", "chop_shop"},
            requiredMembers = 3,
            color = {r = 255, g = 255, b = 0, a = 100}
        },
        
        [9] = {
            name = "Red Light District",
            type = "vice_zone",
            points = {
                {x = 300.0, y = -2000.0},
                {x = 500.0, y = -2000.0},
                {x = 500.0, y = -1800.0},
                {x = 300.0, y = -1800.0}
            },
            center = {x = 400.0, y = -1900.0, z = 20.0},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            baseIncome = 4000,
            bonusMultiplier = 1.0,
            activities = {"prostitution", "gambling", "money_laundering"},
            requiredMembers = 4,
            color = {r = 255, g = 0, b = 255, a = 100}
        },
        
        [10] = {
            name = "Airport Cargo Zone",
            type = "transport_hub",
            points = {
                {x = -1000.0, y = -2500.0},
                {x = -800.0, y = -2500.0},
                {x = -800.0, y = -2300.0},
                {x = -1000.0, y = -2300.0}
            },
            center = {x = -900.0, y = -2400.0, z = 15.0},
            controlledBy = 0,
            contestedBy = 0,
            captureStartTime = 0,
            protectionStartTime = 0,
            captureProgress = 0,
            isBeingCaptured = false,
            isProtected = false,
            baseIncome = 3000,
            bonusMultiplier = 1.0,
            activities = {"cargo_theft", "smuggling", "hijacking"},
            requiredMembers = 4,
            color = {r = 128, g = 128, b = 128, a = 100}
        }
    },
    
    -- Zone type configurations
    zoneTypes = {
        ["gang_territory"] = {
            name = "Gang Territory",
            description = "Traditional gang turf with drug dealing and protection",
            captureBonus = 1000,
            defenseBonus = 500,
            maxLevel = 5
        },
        ["business_district"] = {
            name = "Business District",
            description = "Commercial area with high-value targets",
            captureBonus = 2500,
            defenseBonus = 1000,
            maxLevel = 10
        },
        ["smuggling_zone"] = {
            name = "Smuggling Zone",
            description = "Import/export operations and contraband",
            captureBonus = 1500,
            defenseBonus = 750,
            maxLevel = 7
        },
        ["racing_zone"] = {
            name = "Racing Zone",
            description = "Illegal street racing and vehicle operations",
            captureBonus = 1200,
            defenseBonus = 600,
            maxLevel = 6
        },
        ["vice_zone"] = {
            name = "Vice Zone",
            description = "Entertainment and vice operations",
            captureBonus = 2000,
            defenseBonus = 800,
            maxLevel = 8
        },
        ["transport_hub"] = {
            name = "Transport Hub",
            description = "Strategic transport and logistics control",
            captureBonus = 1800,
            defenseBonus = 700,
            maxLevel = 7
        }
    },
    
    -- Zone levels and upgrades
    zoneLevels = {},
    zoneUpgrades = {
        [1] = {name = "Basic Control", incomeMultiplier = 1.0, defenseBonus = 0},
        [2] = {name = "Established", incomeMultiplier = 1.2, defenseBonus = 10},
        [3] = {name = "Fortified", incomeMultiplier = 1.4, defenseBonus = 20},
        [4] = {name = "Stronghold", incomeMultiplier = 1.6, defenseBonus = 30},
        [5] = {name = "Empire", incomeMultiplier = 1.8, defenseBonus = 40},
        [6] = {name = "Monopoly", incomeMultiplier = 2.0, defenseBonus = 50},
        [7] = {name = "Cartel", incomeMultiplier = 2.2, defenseBonus = 60},
        [8] = {name = "Syndicate", incomeMultiplier = 2.4, defenseBonus = 70},
        [9] = {name = "Dynasty", incomeMultiplier = 2.6, defenseBonus = 80},
        [10] = {name = "Legend", incomeMultiplier = 3.0, defenseBonus = 100}
    },
    
    activeCaptureThreads = {},
    zoneEvents = {}
}

-- Initialize enhanced zone tables
function initializeEnhancedZoneTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `enhanced_zones` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `Type` varchar(32) NOT NULL,
            `ControlledBy` int(11) DEFAULT 0,
            `Level` int(2) DEFAULT 1,
            `Experience` int(11) DEFAULT 0,
            `CaptureTime` datetime DEFAULT NULL,
            `TotalIncome` int(11) DEFAULT 0,
            `DefenseWins` int(11) DEFAULT 0,
            `AttackWins` int(11) DEFAULT 0,
            `CenterX` float NOT NULL,
            `CenterY` float NOT NULL,
            `CenterZ` float NOT NULL,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `zone_activities` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ZoneID` int(11) NOT NULL,
            `FactionID` int(11) NOT NULL,
            `ActivityType` varchar(32) NOT NULL,
            `Income` int(11) NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ZoneID`) REFERENCES `enhanced_zones`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `zone_events` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ZoneID` int(11) NOT NULL,
            `EventType` varchar(32) NOT NULL,
            `Description` varchar(255) NOT NULL,
            `Reward` int(11) DEFAULT 0,
            `StartTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `EndTime` datetime NOT NULL,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `zone_upgrades` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ZoneID` int(11) NOT NULL,
            `UpgradeType` varchar(32) NOT NULL,
            `Level` int(2) DEFAULT 1,
            `Cost` int(11) NOT NULL,
            `PurchaseDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Insert default zones
    for zoneId, zone in pairs(EnhancedZones.zones) do
        MySQL.query([[
            INSERT IGNORE INTO `enhanced_zones` (`ID`, `Name`, `Type`, `CenterX`, `CenterY`, `CenterZ`)
            VALUES (@zoneId, @name, @type, @centerX, @centerY, @centerZ)
        ]], {
            ['@zoneId'] = zoneId,
            ['@name'] = zone.name,
            ['@type'] = zone.type,
            ['@centerX'] = zone.center.x,
            ['@centerY'] = zone.center.y,
            ['@centerZ'] = zone.center.z
        })
    end
end

-- Enhanced zone capture with rewards
function enhancedStartZoneCapture(source, zoneId)
    if not PlayerData[source] or not EnhancedZones.zones[zoneId] then return false end
    if PlayerData[source].FactionID == 0 then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, "You must be in a faction to capture zones!")
        return false
    end
    
    local zone = EnhancedZones.zones[zoneId]
    local attackingFaction = PlayerData[source].FactionID
    
    -- Check if already controlled by same faction
    if zone.controlledBy == attackingFaction then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, "Your faction already controls this zone!")
        return false
    end
    
    -- Check if already being captured
    if zone.isBeingCaptured then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, "This zone is already being captured!")
        return false
    end
    
    -- Check if in protection period
    if zone.isProtected and (os.time() - zone.protectionStartTime) < EnhancedZones.protectionTime then
        local timeLeft = EnhancedZones.protectionTime - (os.time() - zone.protectionStartTime)
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, 
            ("This zone is protected for %d more seconds!"):format(timeLeft))
        return false
    end
    
    -- Check required members
    local factionMembersInZone = 0
    for checkSource, data in pairs(PlayerData) do
        if data.FactionID == attackingFaction then
            local playerZone = getPlayerZone(checkSource)
            if playerZone == zoneId then
                factionMembersInZone = factionMembersInZone + 1
            end
        end
    end
    
    if factionMembersInZone < zone.requiredMembers then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, 
            ("You need at least %d faction members in the zone to capture it!"):format(zone.requiredMembers))
        return false
    end
    
    -- Start enhanced capture process
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
    
    -- Notify all players with enhanced message
    local attackingFactionName = Factions[attackingFaction] and Factions[attackingFaction].Name or "Unknown Faction"
    local zoneTypeName = EnhancedZones.zoneTypes[zone.type].name
    TriggerClientEvent('chatMessage', -1, "[ZONE WAR]", { 255, 0, 0 }, 
        ("%s is attempting to capture %s (%s)!"):format(attackingFactionName, zone.name, zoneTypeName))
    
    -- Start enhanced capture thread
    startEnhancedCaptureThread(zoneId)
    
    -- Update all clients with HUD data
    TriggerClientEvent('scrp:updateZoneHUD', -1, EnhancedZones.zones)
    
    return true
end

-- Enhanced capture completion with leveling
function completeEnhancedZoneCapture(zoneId)
    local zone = EnhancedZones.zones[zoneId]
    local oldController = zone.controlledBy
    local newController = zone.contestedBy
    
    -- Update zone control
    zone.controlledBy = newController
    zone.isBeingCaptured = false
    zone.contestedBy = 0
    zone.isProtected = true
    zone.protectionStartTime = os.time()
    zone.captureProgress = 0
    
    -- Initialize zone level if not exists
    if not EnhancedZones.zoneLevels[zoneId] then
        EnhancedZones.zoneLevels[zoneId] = {level = 1, experience = 0}
    end
    
    -- Calculate capture bonus
    local zoneType = EnhancedZones.zoneTypes[zone.type]
    local captureBonus = zoneType.captureBonus
    
    -- Award capture bonus to faction
    if Factions[newController] then
        Factions[newController].Budget = Factions[newController].Budget + captureBonus
    end
    
    -- Update database
    MySQL.query([[
        UPDATE `enhanced_zones` SET `ControlledBy` = @newController, `CaptureTime` = NOW(), `AttackWins` = `AttackWins` + 1
        WHERE `ID` = @zoneId
    ]], {
        ['@newController'] = newController,
        ['@zoneId'] = zoneId
    })
    
    -- Award experience to participants
    for source, data in pairs(PlayerData) do
        if data.FactionID == newController then
            local playerZone = getPlayerZone(source)
            if playerZone == zoneId then
                addSkillExperience(source, "shooting", 50)
                PlayerData[source].Money = PlayerData[source].Money + 500
                TriggerClientEvent('chatMessage', source, "[ZONES]", { 0, 255, 0 }, 
                    ("Zone captured! +$500, +50 Shooting XP"))
            end
        end
    end
    
    -- Notify all players with enhanced details
    local newFactionName = Factions[newController] and Factions[newController].Name or "Unknown Faction"
    local zoneTypeName = EnhancedZones.zoneTypes[zone.type].name
    TriggerClientEvent('chatMessage', -1, "[ZONE WAR]", { 0, 255, 0 }, 
        ("%s captured %s (%s)! Bonus: $%d"):format(newFactionName, zone.name, zoneTypeName, captureBonus))
    
    -- Start protection and activity threads
    startEnhancedProtectionThread(zoneId)
    startZoneActivityThread(zoneId)
    
    -- Trigger zone event
    triggerRandomZoneEvent(zoneId)
    
    -- Update clients
    TriggerClientEvent('scrp:updateZoneHUD', -1, EnhancedZones.zones)
    TriggerClientEvent('scrp:zoneCaptured', -1, zoneId, newController, oldController)
end

-- Zone activity system
function startZoneActivityThread(zoneId)
    CreateThread(function()
        while EnhancedZones.zones[zoneId] and EnhancedZones.zones[zoneId].controlledBy > 0 do
            Wait(300000) -- 5 minutes
            
            local zone = EnhancedZones.zones[zoneId]
            local controllingFaction = zone.controlledBy
            
            if not Factions[controllingFaction] then break end
            
            -- Generate activity income based on zone type
            for _, activity in ipairs(zone.activities) do
                local income = generateActivityIncome(zoneId, activity)
                if income > 0 then
                    Factions[controllingFaction].Budget = Factions[controllingFaction].Budget + income
                    
                    -- Log activity
                    MySQL.query([[
                        INSERT INTO `zone_activities` (`ZoneID`, `FactionID`, `ActivityType`, `Income`)
                        VALUES (@zoneId, @factionId, @activityType, @income)
                    ]], {
                        ['@zoneId'] = zoneId,
                        ['@factionId'] = controllingFaction,
                        ['@activityType'] = activity,
                        ['@income'] = income
                    })
                    
                    -- Notify faction members
                    for source, data in pairs(PlayerData) do
                        if data.FactionID == controllingFaction then
                            TriggerClientEvent('chatMessage', source, "[ZONE ACTIVITY]", { 0, 255, 0 }, 
                                ("%s generated $%d from %s"):format(zone.name, income, activity:gsub("_", " ")))
                        end
                    end
                end
            end
        end
    end)
end

-- Generate activity income
function generateActivityIncome(zoneId, activity)
    local zone = EnhancedZones.zones[zoneId]
    local baseIncome = zone.baseIncome / #zone.activities
    local zoneLevel = EnhancedZones.zoneLevels[zoneId] and EnhancedZones.zoneLevels[zoneId].level or 1
    local levelMultiplier = EnhancedZones.zoneUpgrades[zoneLevel].incomeMultiplier
    
    -- Activity-specific multipliers
    local activityMultipliers = {
        ["drug_dealing"] = 1.2,
        ["weapon_trading"] = 1.5,
        ["protection_racket"] = 1.0,
        ["business_tax"] = 2.0,
        ["protection_money"] = 1.3,
        ["loan_sharking"] = 1.8,
        ["weapon_smuggling"] = 1.7,
        ["drug_import"] = 1.6,
        ["vehicle_theft"] = 1.4,
        ["illegal_racing"] = 1.1,
        ["car_theft"] = 1.3,
        ["chop_shop"] = 1.5,
        ["prostitution"] = 1.2,
        ["gambling"] = 1.4,
        ["money_laundering"] = 1.9,
        ["cargo_theft"] = 1.6,
        ["smuggling"] = 1.5,
        ["hijacking"] = 1.7
    }
    
    local activityMultiplier = activityMultipliers[activity] or 1.0
    local randomFactor = math.random(80, 120) / 100 -- 80% to 120%
    
    return math.floor(baseIncome * levelMultiplier * activityMultiplier * randomFactor)
end

-- Random zone events
function triggerRandomZoneEvent(zoneId)
    local eventChance = math.random(1, 100)
    if eventChance <= 30 then -- 30% chance
        local zone = EnhancedZones.zones[zoneId]
        local events = {
            {
                type = "police_raid",
                description = "Police raid in progress! Defend the zone!",
                duration = 300, -- 5 minutes
                reward = 2000,
                penalty = -1000
            },
            {
                type = "rival_attack",
                description = "Rival gang spotted in the area!",
                duration = 600, -- 10 minutes
                reward = 1500,
                penalty = -500
            },
            {
                type = "high_value_target",
                description = "High-value target spotted! Eliminate for bonus!",
                duration = 180, -- 3 minutes
                reward = 3000,
                penalty = 0
            },
            {
                type = "supply_drop",
                description = "Supply drop incoming! Secure the area!",
                duration = 240, -- 4 minutes
                reward = 2500,
                penalty = 0
            }
        }
        
        local event = events[math.random(1, #events)]
        local endTime = os.date("%Y-%m-%d %H:%M:%S", os.time() + event.duration)
        
        -- Insert event
        MySQL.query([[
            INSERT INTO `zone_events` (`ZoneID`, `EventType`, `Description`, `Reward`, `EndTime`)
            VALUES (@zoneId, @eventType, @description, @reward, @endTime)
        ]], {
            ['@zoneId'] = zoneId,
            ['@eventType'] = event.type,
            ['@description'] = event.description,
            ['@reward'] = event.reward,
            ['@endTime'] = endTime
        })
        
        -- Notify controlling faction
        local controllingFaction = zone.controlledBy
        for source, data in pairs(PlayerData) do
            if data.FactionID == controllingFaction then
                TriggerClientEvent('chatMessage', source, "[ZONE EVENT]", { 255, 255, 0 }, 
                    ("%s: %s"):format(zone.name, event.description))
                TriggerClientEvent('scrp:zoneEvent', source, zoneId, event)
            end
        end
        
        -- Set event timer
        SetTimeout(event.duration * 1000, function()
            completeZoneEvent(zoneId, event.type)
        end)
    end
end

-- Complete zone event
function completeZoneEvent(zoneId, eventType)
    local zone = EnhancedZones.zones[zoneId]
    if not zone or zone.controlledBy == 0 then return end
    
    -- Get event details
    local query = [[
        SELECT * FROM `zone_events` WHERE `ZoneID` = @zoneId AND `EventType` = @eventType AND `Active` = 1
        ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.query(query, {
        ['@zoneId'] = zoneId,
        ['@eventType'] = eventType
    }, function(rows)
        if #rows > 0 then
            local event = rows[1]
            
            -- Check if faction members are still in zone
            local membersInZone = 0
            for source, data in pairs(PlayerData) do
                if data.FactionID == zone.controlledBy then
                    local playerZone = getPlayerZone(source)
                    if playerZone == zoneId then
                        membersInZone = membersInZone + 1
                    end
                end
            end
            
            local success = membersInZone >= zone.requiredMembers
            local reward = success and event.Reward or event.Penalty or 0
            
            if reward ~= 0 and Factions[zone.controlledBy] then
                Factions[zone.controlledBy].Budget = Factions[zone.controlledBy].Budget + reward
            end
            
            -- Notify faction
            local message = success and 
                ("Event completed successfully! Reward: $%d"):format(reward) or
                ("Event failed! Penalty: $%d"):format(math.abs(reward))
            
            for source, data in pairs(PlayerData) do
                if data.FactionID == zone.controlledBy then
                    TriggerClientEvent('chatMessage', source, "[ZONE EVENT]", 
                        success and { 0, 255, 0 } or { 255, 0, 0 }, message)
                end
            end
            
            -- Mark event as completed
            MySQL.query([[
                UPDATE `zone_events` SET `Active` = 0 WHERE `ID` = @eventId
            ]], {
                ['@eventId'] = event.ID
            })
        end
    end)
end

-- Get player zone (enhanced version)
function getPlayerZone(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    for zoneId, zone in pairs(EnhancedZones.zones) do
        if isPointInPolygon(coords.x, coords.y, zone.points) then
            return zoneId
        end
    end
    
    return nil
end
