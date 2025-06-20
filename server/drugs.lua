-- Drug system

DrugTypes = {
    ["weed"] = {name = "Marijuana", price = 50, effects = {"relaxed", "hungry"}},
    ["cocaine"] = {name = "Cocaine", price = 200, effects = {"energetic", "aggressive"}},
    ["heroin"] = {name = "Heroin", price = 300, effects = {"drowsy", "addicted"}},
    ["meth"] = {name = "Methamphetamine", price = 250, effects = {"paranoid", "energetic"}}
}

DrugLabs = {}
DrugDeals = {}

-- Initialize drug tables
function initializeDrugTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `drug_labs` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `OwnerID` int(11) NOT NULL,
            `DrugType` varchar(16) NOT NULL,
            `LocationX` float NOT NULL,
            `LocationY` float NOT NULL,
            `LocationZ` float NOT NULL,
            `Production` int(11) DEFAULT 0,
            `LastProduction` datetime DEFAULT CURRENT_TIMESTAMP,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`OwnerID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `drug_deals` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `SellerID` int(11) NOT NULL,
            `BuyerID` int(11) NOT NULL,
            `DrugType` varchar(16) NOT NULL,
            `Quantity` int(11) NOT NULL,
            `Price` int(11) NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `drug_effects` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `DrugType` varchar(16) NOT NULL,
            `EffectLevel` int(2) DEFAULT 1,
            `StartTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `Duration` int(11) NOT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to create drug lab
function createDrugLab(source, drugType, x, y, z)
    if not PlayerData[source] then return false end
    if not DrugTypes[drugType] then return false end
    
    local ownerId = PlayerData[source].CharacterID
    local query = [[
        INSERT INTO `drug_labs` (`OwnerID`, `DrugType`, `LocationX`, `LocationY`, `LocationZ`)
        VALUES (@ownerId, @drugType, @x, @y, @z)
    ]]

    MySQL.query(query, {
        ['@ownerId'] = ownerId,
        ['@drugType'] = drugType,
        ['@x'] = x,
        ['@y'] = y,
        ['@z'] = z
    }, function(rows, affected)
        if affected > 0 then
            local labId = MySQL.insertId
            DrugLabs[labId] = {
                ID = labId,
                OwnerID = ownerId,
                DrugType = drugType,
                Location = {x = x, y = y, z = z},
                Production = 0,
                Active = true
            }
            
            TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 255, 0 }, 
                ("Drug lab created for %s production"):format(DrugTypes[drugType].name))
            TriggerClientEvent('scrp:updateDrugLabs', -1, DrugLabs)
        end
    end)
end

-- Function to produce drugs
function produceDrugs(labId)
    if not DrugLabs[labId] or not DrugLabs[labId].Active then return end
    
    local production = math.random(5, 15)
    local query = [[
        UPDATE `drug_labs` SET `Production` = `Production` + @production, `LastProduction` = NOW()
        WHERE `ID` = @labId
    ]]

    MySQL.query(query, {
        ['@production'] = production,
        ['@labId'] = labId
    })
    
    DrugLabs[labId].Production = DrugLabs[labId].Production + production
end

-- Function to sell drugs
function sellDrugs(source, targetSource, drugType, quantity, price)
    if not PlayerData[source] or not PlayerData[targetSource] then return false end
    if not DrugTypes[drugType] then return false end
    
    -- Check if seller has drugs
    local hasDrugs = false
    for _, item in ipairs(PlayerData[source].Inventory) do
        if item.ItemName == drugType and item.Quantity >= quantity then
            hasDrugs = true
            break
        end
    end
    
    if not hasDrugs then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, "You don't have enough drugs!")
        return false
    end
    
    if PlayerData[targetSource].Money < price then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, "Buyer doesn't have enough money!")
        return false
    end
    
    -- Process transaction
    removeItemFromInventory(source, drugType, quantity)
    addItemToInventory(targetSource, drugType, quantity)
    
    PlayerData[source].Money = PlayerData[source].Money + price
    PlayerData[targetSource].Money = PlayerData[targetSource].Money - price
    
    -- Log deal
    local query = [[
        INSERT INTO `drug_deals` (`SellerID`, `BuyerID`, `DrugType`, `Quantity`, `Price`)
        VALUES (@sellerId, @buyerId, @drugType, @quantity, @price)
    ]]

    MySQL.query(query, {
        ['@sellerId'] = PlayerData[source].CharacterID,
        ['@buyerId'] = PlayerData[targetSource].CharacterID,
        ['@drugType'] = drugType,
        ['@quantity'] = quantity,
        ['@price'] = price
    })
    
    TriggerClientEvent('chatMessage', source, "[DRUGS]", { 0, 255, 0 }, 
        ("Sold %dx %s for $%d"):format(quantity, DrugTypes[drugType].name, price))
    TriggerClientEvent('chatMessage', targetSource, "[DRUGS]", { 255, 255, 0 }, 
        ("Bought %dx %s for $%d"):format(quantity, DrugTypes[drugType].name, price))
end

-- Function to use drugs
function useDrugs(source, drugType)
    if not PlayerData[source] then return false end
    if not DrugTypes[drugType] then return false end
    
    -- Check if player has drugs
    local hasDrugs = false
    for _, item in ipairs(PlayerData[source].Inventory) do
        if item.ItemName == drugType and item.Quantity > 0 then
            hasDrugs = true
            break
        end
    end
    
    if not hasDrugs then
        TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 0, 0 }, "You don't have any drugs!")
        return false
    end
    
    -- Remove drug from inventory
    removeItemFromInventory(source, drugType, 1)
    
    -- Apply effects
    local duration = math.random(300, 600) -- 5-10 minutes
    local query = [[
        INSERT INTO `drug_effects` (`CharacterID`, `DrugType`, `Duration`)
        VALUES (@characterId, @drugType, @duration)
    ]]

    MySQL.query(query, {
        ['@characterId'] = PlayerData[source].CharacterID,
        ['@drugType'] = drugType,
        ['@duration'] = duration
    })
    
    TriggerClientEvent('scrp:applyDrugEffects', source, drugType, DrugTypes[drugType].effects, duration)
    TriggerClientEvent('chatMessage', source, "[DRUGS]", { 255, 255, 0 }, 
        ("You used %s"):format(DrugTypes[drugType].name))
end

-- Drug production timer
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        for labId, _ in pairs(DrugLabs) do
            produceDrugs(labId)
        end
    end
end)
