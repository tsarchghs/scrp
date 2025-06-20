-- Weapon system

WeaponShops = {
    {x = 1692.41, y = 3759.50, z = 34.70, name = "Ammu-Nation Sandy Shores"},
    {x = 252.63, y = -50.00, z = 69.94, name = "Ammu-Nation Downtown"},
    {x = 22.56, y = -1107.28, z = 29.80, name = "Ammu-Nation South LS"},
    {x = 2567.69, y = 294.38, z = 108.73, name = "Ammu-Nation Paleto Bay"}
}

WeaponLicenses = {}
CombatLog = {}

-- Initialize weapon tables
function initializeWeaponTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `weapon_licenses` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `LicenseType` varchar(32) NOT NULL,
            `IssueDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ExpiryDate` datetime NOT NULL,
            `Status` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `weapon_purchases` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `WeaponHash` varchar(32) NOT NULL,
            `SerialNumber` varchar(16) NOT NULL,
            `PurchaseDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ShopLocation` varchar(64) NOT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `combat_log` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `AttackerID` int(11) DEFAULT NULL,
            `VictimID` int(11) NOT NULL,
            `WeaponHash` varchar(32) NOT NULL,
            `Damage` float NOT NULL,
            `BodyPart` int(3) NOT NULL,
            `Distance` float NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to issue weapon license
function issueWeaponLicense(source, targetId, licenseType, duration)
    if not PlayerData[targetId] then return false end
    
    local characterId = PlayerData[targetId].CharacterID
    local expiryDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + (duration * 24 * 60 * 60))
    
    local query = [[
        INSERT INTO `weapon_licenses` (`CharacterID`, `LicenseType`, `ExpiryDate`)
        VALUES (@characterId, @licenseType, @expiryDate)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@licenseType'] = licenseType,
        ['@expiryDate'] = expiryDate
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', targetId, "[LICENSE]", { 0, 255, 0 }, 
                ("You have been issued a %s license valid for %d days"):format(licenseType, duration))
            TriggerClientEvent('chatMessage', source, "[LICENSE]", { 0, 255, 0 }, 
                ("Issued %s license to %s"):format(licenseType, PlayerData[targetId].Name))
        end
    end)
end

-- Function to check weapon license
function hasWeaponLicense(source, licenseType)
    if not PlayerData[source] then return false end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        SELECT * FROM `weapon_licenses` 
        WHERE `CharacterID` = @characterId AND `LicenseType` = @licenseType 
        AND `ExpiryDate` > NOW() AND `Status` = 1
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@licenseType'] = licenseType
    }, function(rows)
        return #rows > 0
    end)
end

-- Function to log weapon purchase
function logWeaponPurchase(source, weaponHash, shopLocation)
    if not PlayerData[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    local serialNumber = generateSerialNumber()
    
    local query = [[
        INSERT INTO `weapon_purchases` (`CharacterID`, `WeaponHash`, `SerialNumber`, `ShopLocation`)
        VALUES (@characterId, @weaponHash, @serialNumber, @shopLocation)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@weaponHash'] = weaponHash,
        ['@serialNumber'] = serialNumber,
        ['@shopLocation'] = shopLocation
    })
end

-- Function to generate weapon serial number
function generateSerialNumber()
    local serial = ""
    for i = 1, 8 do
        serial = serial .. string.char(math.random(65, 90)) -- A-Z
    end
    for i = 1, 4 do
        serial = serial .. math.random(0, 9)
    end
    return serial
end

-- Function to log combat
function logCombat(attackerId, victimId, weaponHash, damage, bodyPart, distance)
    local query = [[
        INSERT INTO `combat_log` (`AttackerID`, `VictimID`, `WeaponHash`, `Damage`, `BodyPart`, `Distance`)
        VALUES (@attackerId, @victimId, @weaponHash, @damage, @bodyPart, @distance)
    ]]

    MySQL.query(query, {
        ['@attackerId'] = attackerId,
        ['@victimId'] = victimId,
        ['@weaponHash'] = weaponHash,
        ['@damage'] = damage,
        ['@bodyPart'] = bodyPart,
        ['@distance'] = distance
    })
end
