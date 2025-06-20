-- Gang territory system

Territories = {
    [1] = {
        name = "Grove Street",
        points = {
            {x = 100.0, y = -1900.0},
            {x = 200.0, y = -1900.0},
            {x = 200.0, y = -1800.0},
            {x = 100.0, y = -1800.0}
        },
        controlledBy = 0,
        contestTime = 0,
        income = 1000
    },
    [2] = {
        name = "Ballas Territory",
        points = {
            {x = 300.0, y = -2000.0},
            {x = 400.0, y = -2000.0},
            {x = 400.0, y = -1900.0},
            {x = 300.0, y = -1900.0}
        },
        controlledBy = 0,
        contestTime = 0,
        income = 1200
    },
    [3] = {
        name = "Vagos Hood",
        points = {
            {x = 500.0, y = -1700.0},
            {x = 600.0, y = -1700.0},
            {x = 600.0, y = -1600.0},
            {x = 500.0, y = -1600.0}
        },
        controlledBy = 0,
        contestTime = 0,
        income = 800
    }
}

TerritoryWars = {}

-- Initialize gang tables
function initializeGangTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `gang_territories` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `TerritoryID` int(11) NOT NULL,
            `ControlledBy` int(11) DEFAULT 0,
            `CaptureTime` datetime DEFAULT NULL,
            `LastIncome` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            UNIQUE KEY `TerritoryID` (`TerritoryID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `gang_wars` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `TerritoryID` int(11) NOT NULL,
            `AttackingFaction` int(11) NOT NULL,
            `DefendingFaction` int(11) NOT NULL,
            `StartTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `EndTime` datetime DEFAULT NULL,
            `Winner` int(11) DEFAULT NULL,
            `AttackerKills` int(11) DEFAULT 0,
            `DefenderKills` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Insert default territories
    for territoryId, _ in pairs(Territories) do
        MySQL.query([[
            INSERT IGNORE INTO `gang_territories` (`TerritoryID`) VALUES (@territoryId)
        ]], {
            ['@territoryId'] = territoryId
        })
    end
end

-- Function to start territory war
function startTerritoryWar(source, territoryId)
    if not PlayerData[source] then return false end
    if not Territories[territoryId] then return false end
    if PlayerData[source].FactionID == 0 then
        TriggerClientEvent('chatMessage', source, "[GANG]", { 255, 0, 0 }, "You must be in a gang to start a territory war!")
        return false
    end
    
    local attackingFaction = PlayerData[source].FactionID
    local defendingFaction = Territories[territoryId].controlledBy
    
    if attackingFaction == defendingFaction then
        TriggerClientEvent('chatMessage', source, "[GANG]", { 255, 0, 0 }, "You already control this territory!")
        return false
    end
    
    if TerritoryWars[territoryId] then
        TriggerClientEvent('chatMessage', source, "[GANG]", { 255, 0, 0 }, "Territory war already in progress!")
        return false
    end
    
    -- Start war
    local query = [[
        INSERT INTO `gang_wars` (`TerritoryID`, `AttackingFaction`, `DefendingFaction`)
        VALUES (@territoryId, @attackingFaction, @defendingFaction)
    ]]

    MySQL.query(query, {
        ['@territoryId'] = territoryId,
        ['@attackingFaction'] = attackingFaction,
        ['@defendingFaction'] = defendingFaction
    }, function(rows, affected)
        if affected > 0 then
            local warId = MySQL.insertId
            TerritoryWars[territoryId] = {
                ID = warId,
                AttackingFaction = attackingFaction,
                DefendingFaction = defendingFaction,
                StartTime = os.time(),
                AttackerKills = 0,
                DefenderKills = 0,
                Duration = 1800 -- 30 minutes
            }
            
            -- Notify all players
            TriggerClientEvent('chatMessage', -1, "[GANG WAR]", { 255, 0, 0 }, 
                ("Territory war started in %s!"):format(Territories[territoryId].name))
            TriggerClientEvent('scrp:startTerritoryWar', -1, territoryId, TerritoryWars[territoryId])
            
            -- Set timer to end war
            SetTimeout(1800000, function() -- 30 minutes
                endTerritoryWar(territoryId)
            end)
        end
    end)
end

-- Function to end territory war
function endTerritoryWar(territoryId)
    if not TerritoryWars[territoryId] then return end
    
    local war = TerritoryWars[territoryId]
    local winner = 0
    
    if war.AttackerKills > war.DefenderKills then
        winner = war.AttackingFaction
        Territories[territoryId].controlledBy = war.AttackingFaction
    elseif war.DefenderKills > war.AttackerKills then
        winner = war.DefendingFaction
    end
    
    -- Update database
    local query = [[
        UPDATE `gang_wars` SET `EndTime` = NOW(), `Winner` = @winner,
        `AttackerKills` = @attackerKills, `DefenderKills` = @defenderKills
        WHERE `ID` = @warId
    ]]

    MySQL.query(query, {
        ['@winner'] = winner,
        ['@attackerKills'] = war.AttackerKills,
        ['@defenderKills'] = war.DefenderKills,
        ['@warId'] = war.ID
    })
    
    if winner > 0 then
        MySQL.query([[
            UPDATE `gang_territories` SET `ControlledBy` = @winner, `CaptureTime` = NOW()
            WHERE `TerritoryID` = @territoryId
        ]], {
            ['@winner'] = winner,
            ['@territoryId'] = territoryId
        })
        
        local factionName = Factions[winner] and Factions[winner].Name or "Unknown Gang"
        TriggerClientEvent('chatMessage', -1, "[GANG WAR]", { 0, 255, 0 }, 
            ("%s has captured %s!"):format(factionName, Territories[territoryId].name))
    else
        TriggerClientEvent('chatMessage', -1, "[GANG WAR]", { 255, 255, 0 }, 
            ("Territory war in %s ended in a draw!"):format(Territories[territoryId].name))
    end
    
    TerritoryWars[territoryId] = nil
    TriggerClientEvent('scrp:endTerritoryWar', -1, territoryId)
end

-- Function to handle gang kill
function handleGangKill(killerId, victimId, territoryId)
    if not TerritoryWars[territoryId] then return end
    if not PlayerData[killerId] or not PlayerData[victimId] then return end
    
    local killerFaction = PlayerData[killerId].FactionID
    local war = TerritoryWars[territoryId]
    
    if killerFaction == war.AttackingFaction then
        war.AttackerKills = war.AttackerKills + 1
    elseif killerFaction == war.DefendingFaction then
        war.DefenderKills = war.DefenderKills + 1
    end
    
    TriggerClientEvent('scrp:updateWarScore', -1, territoryId, war.AttackerKills, war.DefenderKills)
end

-- Territory income system
CreateThread(function()
    while true do
        Wait(3600000) -- 1 hour
        
        for territoryId, territory in pairs(Territories) do
            if territory.controlledBy > 0 and Factions[territory.controlledBy] then
                Factions[territory.controlledBy].Budget = Factions[territory.controlledBy].Budget + territory.income
                
                -- Update database
                MySQL.query([[
                    UPDATE `factions` SET `Budget` = @budget WHERE `ID` = @factionId
                ]], {
                    ['@budget'] = Factions[territory.controlledBy].Budget,
                    ['@factionId'] = territory.controlledBy
                })
                
                -- Notify faction members
                for source, data in pairs(PlayerData) do
                    if data.FactionID == territory.controlledBy then
                        TriggerClientEvent('chatMessage', source, "[TERRITORY]", { 0, 255, 0 }, 
                            ("Your gang earned $%d from %s"):format(territory.income, territory.name))
                    end
                end
            end
        end
    end
end)
