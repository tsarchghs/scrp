-- Hitman/Contract System for SC:RP FiveM

Contracts = {}
HitmanData = {}

-- Initialize hitman tables
function initializeHitmanTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `hitman_contracts` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ClientID` int(11) NOT NULL,
            `TargetID` int(11) NOT NULL,
            `HitmanID` int(11) DEFAULT NULL,
            `Reward` int(11) NOT NULL,
            `Reason` varchar(255) DEFAULT NULL,
            `Status` varchar(16) DEFAULT 'open',
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `AcceptedDate` datetime DEFAULT NULL,
            `CompletedDate` datetime DEFAULT NULL,
            `ExpiryDate` datetime NOT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ClientID`) REFERENCES `characters`(`ID`),
            FOREIGN KEY (`TargetID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `hitman_reputation` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `ContractsCompleted` int(11) DEFAULT 0,
            `ContractsFailed` int(11) DEFAULT 0,
            `TotalEarnings` int(11) DEFAULT 0,
            `Reputation` int(11) DEFAULT 0,
            `LastContract` datetime DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `CharacterID` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Load hitman data
function loadHitmanData(source, characterId)
    local query = [[
        SELECT * FROM `hitman_reputation` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local data = rows[1]
            HitmanData[source] = {
                contractsCompleted = data.ContractsCompleted,
                contractsFailed = data.ContractsFailed,
                totalEarnings = data.TotalEarnings,
                reputation = data.Reputation,
                lastContract = data.LastContract
            }
        else
            -- Create new hitman record
            MySQL.query([[
                INSERT INTO `hitman_reputation` (`CharacterID`) VALUES (@characterId)
            ]], {
                ['@characterId'] = characterId
            })
            
            HitmanData[source] = {
                contractsCompleted = 0,
                contractsFailed = 0,
                totalEarnings = 0,
                reputation = 0,
                lastContract = nil
            }
        end
    end)
end

-- Load active contracts
function loadContracts()
    local query = [[
        SELECT hc.*, 
               c1.Name as ClientName, 
               c2.Name as TargetName,
               c3.Name as HitmanName
        FROM `hitman_contracts` hc
        JOIN `characters` c1 ON hc.ClientID = c1.ID
        JOIN `characters` c2 ON hc.TargetID = c2.ID
        LEFT JOIN `characters` c3 ON hc.HitmanID = c3.ID
        WHERE hc.Status IN ('open', 'accepted') AND hc.ExpiryDate > NOW()
    ]]

    MySQL.query(query, {}, function(rows)
        Contracts = {}
        for i = 1, #rows do
            local contract = rows[i]
            Contracts[contract.ID] = {
                ID = contract.ID,
                ClientID = contract.ClientID,
                ClientName = contract.ClientName,
                TargetID = contract.TargetID,
                TargetName = contract.TargetName,
                HitmanID = contract.HitmanID,
                HitmanName = contract.HitmanName,
                Reward = contract.Reward,
                Reason = contract.Reason,
                Status = contract.Status,
                CreatedDate = contract.CreatedDate,
                AcceptedDate = contract.AcceptedDate,
                ExpiryDate = contract.ExpiryDate
            }
        end
        print(("[SC:RP] Loaded %d active contracts"):format(#rows))
    end)
end

-- Create a contract
function createContract(source, targetCharacterId, reward, reason, durationHours)
    if not PlayerData[source] then return false end
    
    local clientId = PlayerData[source].CharacterID
    
    -- Check if client has enough money
    if PlayerData[source].Money < reward then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    -- Check if target exists
    local targetExists = false
    local targetName = "Unknown"
    for targetSource, data in pairs(PlayerData) do
        if data.CharacterID == targetCharacterId then
            targetExists = true
            targetName = data.Name
            break
        end
    end
    
    if not targetExists then
        -- Check database for offline player
        MySQL.query([[
            SELECT Name FROM `characters` WHERE `ID` = @targetId
        ]], {
            ['@targetId'] = targetCharacterId
        }, function(rows)
            if #rows > 0 then
                targetName = rows[1].Name
                targetExists = true
            end
        end)
        
        if not targetExists then
            TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "Target not found!")
            return false
        end
    end
    
    -- Check if targeting self
    if clientId == targetCharacterId then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "You cannot place a contract on yourself!")
        return false
    end
    
    -- Deduct money from client
    PlayerData[source].Money = PlayerData[source].Money - reward
    
    -- Calculate expiry date
    local expiryDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + (durationHours * 3600))
    
    -- Create contract
    local query = [[
        INSERT INTO `hitman_contracts` (`ClientID`, `TargetID`, `Reward`, `Reason`, `ExpiryDate`)
        VALUES (@clientId, @targetId, @reward, @reason, @expiryDate)
    ]]

    MySQL.query(query, {
        ['@clientId'] = clientId,
        ['@targetId'] = targetCharacterId,
        ['@reward'] = reward,
        ['@reason'] = reason,
        ['@expiryDate'] = expiryDate
    }, function(rows, affected)
        if affected > 0 then
            local contractId = MySQL.insertId
            
            TriggerClientEvent('chatMessage', source, "[HITMAN]", { 0, 255, 0 }, 
                ("Contract placed on %s for $%d (Contract ID: %d)"):format(targetName, reward, contractId))
            
            -- Reload contracts
            loadContracts()
            
            -- Notify potential hitmen
            for hitmanSource, data in pairs(PlayerData) do
                if HitmanData[hitmanSource] and HitmanData[hitmanSource].reputation >= 10 then
                    TriggerClientEvent('chatMessage', hitmanSource, "[HITMAN]", { 255, 255, 0 }, 
                        ("New contract available: %s - $%d reward"):format(targetName, reward))
                end
            end
        end
    end)
    
    return true
end

-- Accept a contract
function acceptContract(source, contractId)
    if not PlayerData[source] or not Contracts[contractId] then return false end
    
    local contract = Contracts[contractId]
    
    if contract.Status ~= "open" then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "Contract is no longer available!")
        return false
    end
    
    -- Check hitman reputation
    if not HitmanData[source] or HitmanData[source].reputation < 10 then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "You need at least 10 reputation to accept contracts!")
        return false
    end
    
    -- Check if hitman is the target
    if PlayerData[source].CharacterID == contract.TargetID then
        TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, "You cannot accept a contract on yourself!")
        return false
    end
    
    -- Update contract
    local query = [[
        UPDATE `hitman_contracts` SET `HitmanID` = @hitmanId, `Status` = 'accepted', `AcceptedDate` = NOW()
        WHERE `ID` = @contractId
    ]]

    MySQL.query(query, {
        ['@hitmanId'] = PlayerData[source].CharacterID,
        ['@contractId'] = contractId
    }, function(rows, affected)
        if affected > 0 then
            contract.HitmanID = PlayerData[source].CharacterID
            contract.HitmanName = PlayerData[source].Name
            contract.Status = "accepted"
            
            TriggerClientEvent('chatMessage', source, "[HITMAN]", { 0, 255, 0 }, 
                ("You accepted the contract on %s for $%d"):format(contract.TargetName, contract.Reward))
            
            -- Notify client
            for clientSource, data in pairs(PlayerData) do
                if data.CharacterID == contract.ClientID then
                    TriggerClientEvent('chatMessage', clientSource, "[HITMAN]", { 255, 255, 0 }, 
                        ("Your contract on %s has been accepted by a hitman"):format(contract.TargetName))
                    break
                end
            end
            
            -- Set contract timer
            setContractTimer(contractId)
        end
    end)
    
    return true
end

-- Complete a contract
function completeContract(killerId, victimId)
    if not PlayerData[killerId] or not PlayerData[victimId] then return end
    
    local killerCharacterId = PlayerData[killerId].CharacterID
    local victimCharacterId = PlayerData[victimId].CharacterID
    
    -- Find active contract
    local contractId = nil
    for id, contract in pairs(Contracts) do
        if contract.Status == "accepted" and 
           contract.HitmanID == killerCharacterId and 
           contract.TargetID == victimCharacterId then
            contractId = id
            break
        end
    end
    
    if not contractId then return end
    
    local contract = Contracts[contractId]
    
    -- Update contract status
    local query = [[
        UPDATE `hitman_contracts` SET `Status` = 'completed', `CompletedDate` = NOW()
        WHERE `ID` = @contractId
    ]]

    MySQL.query(query, {
        ['@contractId'] = contractId
    })
    
    -- Pay hitman
    PlayerData[killerId].Money = PlayerData[killerId].Money + contract.Reward
    
    -- Update hitman reputation
    if HitmanData[killerId] then
        HitmanData[killerId].contractsCompleted = HitmanData[killerId].contractsCompleted + 1
        HitmanData[killerId].totalEarnings = HitmanData[killerId].totalEarnings + contract.Reward
        HitmanData[killerId].reputation = HitmanData[killerId].reputation + 25
        
        saveHitmanData(killerId)
    end
    
    -- Notify players
    TriggerClientEvent('chatMessage', killerId, "[HITMAN]", { 0, 255, 0 }, 
        ("Contract completed! You earned $%d and 25 reputation"):format(contract.Reward))
    
    -- Notify client
    for clientSource, data in pairs(PlayerData) do
        if data.CharacterID == contract.ClientID then
            TriggerClientEvent('chatMessage', clientSource, "[HITMAN]", { 0, 255, 0 }, 
                ("Your contract on %s has been completed"):format(contract.TargetName))
            break
        end
    end
    
    -- Remove from active contracts
    Contracts[contractId] = nil
end

-- Set contract timer
function setContractTimer(contractId)
    CreateThread(function()
        local contract = Contracts[contractId]
        if not contract then return end
        
        local expiryTime = os.time(contract.ExpiryDate)
        
        while Contracts[contractId] and os.time() < expiryTime do
            Wait(60000) -- Check every minute
        end
        
        -- Contract expired
        if Contracts[contractId] and Contracts[contractId].Status == "accepted" then
            failContract(contractId)
        end
    end)
end

-- Fail a contract
function failContract(contractId)
    local contract = Contracts[contractId]
    if not contract then return end
    
    -- Update contract status
    MySQL.query([[
        UPDATE `hitman_contracts` SET `Status` = 'failed'
        WHERE `ID` = @contractId
    ]], {
        ['@contractId'] = contractId
    })
    
    -- Update hitman reputation
    for source, data in pairs(PlayerData) do
        if data.CharacterID == contract.HitmanID then
            if HitmanData[source] then
                HitmanData[source].contractsFailed = HitmanData[source].contractsFailed + 1
                HitmanData[source].reputation = math.max(0, HitmanData[source].reputation - 15)
                
                saveHitmanData(source)
                
                TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 0, 0 }, 
                    ("Contract failed! Reputation -15"))
            end
            break
        end
    end
    
    -- Refund client
    for source, data in pairs(PlayerData) do
        if data.CharacterID == contract.ClientID then
            PlayerData[source].Money = PlayerData[source].Money + contract.Reward
            TriggerClientEvent('chatMessage', source, "[HITMAN]", { 255, 255, 0 }, 
                ("Your contract expired. $%d refunded."):format(contract.Reward))
            break
        end
    end
    
    -- Remove from active contracts
    Contracts[contractId] = nil
end

-- Save hitman data
function saveHitmanData(source)
    if not PlayerData[source] or not HitmanData[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    local data = HitmanData[source]
    
    MySQL.query([[
        UPDATE `hitman_reputation` SET 
        `ContractsCompleted` = @completed, `ContractsFailed` = @failed,
        `TotalEarnings` = @earnings, `Reputation` = @reputation, `LastContract` = NOW()
        WHERE `CharacterID` = @characterId
    ]], {
        ['@completed'] = data.contractsCompleted,
        ['@failed'] = data.contractsFailed,
        ['@earnings'] = data.totalEarnings,
        ['@reputation'] = data.reputation,
        ['@characterId'] = characterId
    })
end
