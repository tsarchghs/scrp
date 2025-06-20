-- Banking system

ATMLocations = {
    {x = 147.4, y = -1035.8, z = 29.34},
    {x = -846.304, y = -340.402, z = 38.687},
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -2975.72, y = 379.193, z = 15.020},
    {x = -112.202, y = 6469.295, z = 31.626}
}

BankLocations = {
    {x = 150.266, y = -1040.203, z = 29.374, name = "Fleeca Bank"},
    {x = -1212.980, y = -330.841, z = 37.787, name = "Fleeca Bank"},
    {x = -2962.582, y = 482.627, z = 15.703, name = "Fleeca Bank"}
}

-- Function to initialize banking tables
function initializeBankingTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `bank_accounts` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `AccountNumber` varchar(16) NOT NULL,
            `Balance` int(11) DEFAULT 0,
            `PIN` varchar(4) NOT NULL,
            `Frozen` int(1) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `AccountNumber` (`AccountNumber`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `bank_transactions` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `Type` varchar(16) NOT NULL,
            `Amount` int(11) NOT NULL,
            `Description` varchar(128) DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`AccountID`) REFERENCES `bank_accounts`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to create bank account
function createBankAccount(source, pin)
    if not PlayerData[source] then return false end
    
    local characterId = PlayerData[source].CharacterID
    local accountNumber = generateAccountNumber()
    
    local query = [[
        INSERT INTO `bank_accounts` (`CharacterID`, `AccountNumber`, `PIN`)
        VALUES (@characterId, @accountNumber, @pin)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@accountNumber'] = accountNumber,
        ['@pin'] = pin
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', source, "[BANK]", { 0, 255, 0 }, 
                ("Bank account created! Account Number: %s"):format(accountNumber))
        end
    end)
end

-- Function to generate account number
function generateAccountNumber()
    local number = ""
    for i = 1, 12 do
        number = number .. math.random(0, 9)
    end
    return number
end

-- Function to deposit money
function depositMoney(source, amount)
    if not PlayerData[source] then return false end
    if PlayerData[source].Money < amount then
        TriggerClientEvent('chatMessage', source, "[BANK]", { 255, 0, 0 }, "Insufficient cash!")
        return false
    end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        SELECT `ID` FROM `bank_accounts` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local accountId = rows[1].ID
            
            -- Update bank balance
            local updateQuery = [[
                UPDATE `bank_accounts` SET `Balance` = `Balance` + @amount WHERE `ID` = @accountId
            ]]
            
            MySQL.query(updateQuery, {
                ['@amount'] = amount,
                ['@accountId'] = accountId
            }, function()
                -- Record transaction
                recordTransaction(accountId, "DEPOSIT", amount, "Cash deposit")
                
                -- Update player data
                PlayerData[source].Money = PlayerData[source].Money - amount
                PlayerData[source].BankMoney = PlayerData[source].BankMoney + amount
                
                TriggerClientEvent('chatMessage', source, "[BANK]", { 0, 255, 0 }, 
                    ("Deposited $%d. New balance: $%d"):format(amount, PlayerData[source].BankMoney))
            end)
        end
    end)
end

-- Function to withdraw money
function withdrawMoney(source, amount)
    if not PlayerData[source] then return false end
    if PlayerData[source].BankMoney < amount then
        TriggerClientEvent('chatMessage', source, "[BANK]", { 255, 0, 0 }, "Insufficient bank balance!")
        return false
    end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        SELECT `ID` FROM `bank_accounts` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local accountId = rows[1].ID
            
            -- Update bank balance
            local updateQuery = [[
                UPDATE `bank_accounts` SET `Balance` = `Balance` - @amount WHERE `ID` = @accountId
            ]]
            
            MySQL.query(updateQuery, {
                ['@amount'] = amount,
                ['@accountId'] = accountId
            }, function()
                -- Record transaction
                recordTransaction(accountId, "WITHDRAWAL", amount, "Cash withdrawal")
                
                -- Update player data
                PlayerData[source].Money = PlayerData[source].Money + amount
                PlayerData[source].BankMoney = PlayerData[source].BankMoney - amount
                
                TriggerClientEvent('chatMessage', source, "[BANK]", { 0, 255, 0 }, 
                    ("Withdrew $%d. New balance: $%d"):format(amount, PlayerData[source].BankMoney))
            end)
        end
    end)
end

-- Function to record transaction
function recordTransaction(accountId, type, amount, description)
    local query = [[
        INSERT INTO `bank_transactions` (`AccountID`, `Type`, `Amount`, `Description`)
        VALUES (@accountId, @type, @amount, @description)
    ]]

    MySQL.query(query, {
        ['@accountId'] = accountId,
        ['@type'] = type,
        ['@amount'] = amount,
        ['@description'] = description
    })
end
