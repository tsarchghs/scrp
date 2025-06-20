-- Medical system

Hospitals = {
    {x = 1839.6, y = 3672.93, z = 34.28, name = "Sandy Shores Medical Center"},
    {x = -449.67, y = -340.83, z = 34.50, name = "Central Los Santos Medical Center"},
    {x = 357.43, y = -593.36, z = 28.79, name = "Pillbox Hill Medical Center"},
    {x = -247.76, y = 6331.23, z = 32.43, name = "Paleto Bay Medical Center"}
}

InjuryTypes = {
    [0] = "Head Injury",
    [1] = "Chest Injury", 
    [2] = "Stomach Injury",
    [3] = "Arm Injury",
    [4] = "Leg Injury",
    [5] = "General Trauma"
}

-- Initialize medical tables
function initializeMedicalTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `medical_records` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `InjuryType` int(2) NOT NULL,
            `Severity` int(2) NOT NULL,
            `TreatedBy` int(11) DEFAULT NULL,
            `Treatment` varchar(128) DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `medical_supplies` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `HospitalID` int(11) NOT NULL,
            `ItemName` varchar(32) NOT NULL,
            `Quantity` int(11) DEFAULT 0,
            `LastRestocked` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to injure player
function injurePlayer(source, injuryType, severity)
    if not PlayerData[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        INSERT INTO `medical_records` (`CharacterID`, `InjuryType`, `Severity`)
        VALUES (@characterId, @injuryType, @severity)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@injuryType'] = injuryType,
        ['@severity'] = severity
    })
    
    -- Apply injury effects
    TriggerClientEvent('scrp:applyInjury', source, injuryType, severity)
    
    local injuryName = InjuryTypes[injuryType] or "Unknown Injury"
    TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 255, 0, 0 }, 
        ("You have sustained a %s (Severity: %d/5)"):format(injuryName, severity))
end

-- Function to treat player
function treatPlayer(source, targetSource, treatment)
    if not PlayerData[source] or not PlayerData[targetSource] then return end
    if PlayerData[source].JobID ~= 6 then -- Not a medic
        TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 255, 0, 0 }, "You are not a qualified medic!")
        return
    end
    
    local targetCharacterId = PlayerData[targetSource].CharacterID
    local medicCharacterId = PlayerData[source].CharacterID
    
    local query = [[
        UPDATE `medical_records` SET `TreatedBy` = @medicId, `Treatment` = @treatment
        WHERE `CharacterID` = @targetId AND `TreatedBy` IS NULL
        ORDER BY `Timestamp` DESC LIMIT 1
    ]]

    MySQL.query(query, {
        ['@medicId'] = medicCharacterId,
        ['@treatment'] = treatment,
        ['@targetId'] = targetCharacterId
    }, function(rows, affected)
        if affected > 0 then
            -- Heal player
            TriggerClientEvent('scrp:healPlayer', targetSource)
            
            TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 0, 255, 0 }, 
                ("You treated %s"):format(PlayerData[targetSource].Name))
            TriggerClientEvent('chatMessage', targetSource, "[MEDICAL]", { 0, 255, 0 }, 
                ("You were treated by Dr. %s"):format(PlayerData[source].Name))
        end
    end)
end

-- Function to revive player
function revivePlayer(source, targetSource)
    if not PlayerData[source] or not PlayerData[targetSource] then return end
    if PlayerData[source].JobID ~= 6 then -- Not a medic
        TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 255, 0, 0 }, "You are not a qualified medic!")
        return
    end
    
    TriggerClientEvent('scrp:revivePlayer', targetSource)
    TriggerClientEvent('chatMessage', source, "[MEDICAL]", { 0, 255, 0 }, 
        ("You revived %s"):format(PlayerData[targetSource].Name))
    TriggerClientEvent('chatMessage', targetSource, "[MEDICAL]", { 0, 255, 0 }, 
        ("You were revived by Dr. %s"):format(PlayerData[source].Name))
end
