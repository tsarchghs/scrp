-- Property system

Properties = {}

-- Initialize properties table
function initializePropertiesTable()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `properties` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Type` int(2) DEFAULT 0,
            `Name` varchar(64) NOT NULL,
            `OwnerID` int(11) DEFAULT 0,
            `Price` int(11) DEFAULT 50000,
            `EntranceX` float NOT NULL,
            `EntranceY` float NOT NULL,
            `EntranceZ` float NOT NULL,
            `ExitX` float DEFAULT 0.0,
            `ExitY` float DEFAULT 0.0,
            `ExitZ` float DEFAULT 0.0,
            `Interior` int(11) DEFAULT 0,
            `Locked` int(1) DEFAULT 1,
            `Rent` int(11) DEFAULT 0,
            `RentTime` datetime DEFAULT NULL,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to load all properties
function loadProperties()
    local query = [[
        SELECT * FROM `properties`
    ]]

    MySQL.Async.fetchAll(query, {}, function(rows)
        Properties = {}
        for i = 1, #rows do
            local property = rows[i]
            Properties[property.ID] = {
                ID = property.ID,
                Type = property.Type, -- 0 = House, 1 = Business
                Name = property.Name,
                OwnerID = property.OwnerID,
                Price = property.Price,
                Entrance = {x = property.EntranceX, y = property.EntranceY, z = property.EntranceZ},
                Exit = {x = property.ExitX, y = property.ExitY, z = property.ExitZ},
                Interior = property.Interior,
                Locked = property.Locked,
                Rent = property.Rent,
                RentTime = property.RentTime
            }
        end
        print(("[SC:RP] Loaded %d properties"):format(#rows))
        
        -- Create property markers and blips
        TriggerClientEvent('scrp:updateProperties', -1, Properties)
    end)
end

-- Function to create a new property
function createProperty(type, name, price, entranceX, entranceY, entranceZ, exitX, exitY, exitZ, interior)
    local query = [[
        INSERT INTO `properties` (`Type`, `Name`, `Price`, `EntranceX`, `EntranceY`, `EntranceZ`, `ExitX`, `ExitY`, `ExitZ`, `Interior`)
        VALUES (@type, @name, @price, @entranceX, @entranceY, @entranceZ, @exitX, @exitY, @exitZ, @interior)
    ]]

    MySQL.Async.execute(query, {
        ['@type'] = type,
        ['@name'] = name,
        ['@price'] = price,
        ['@entranceX'] = entranceX,
        ['@entranceY'] = entranceY,
        ['@entranceZ'] = entranceZ,
        ['@exitX'] = exitX,
        ['@exitY'] = exitY,
        ['@exitZ'] = exitZ,
        ['@interior'] = interior
    }, function(rows, affected)
        if affected > 0 then
            loadProperties() -- Reload properties
            print(("[SC:RP] Property %s created"):format(name))
        end
    end)
end

-- Function to buy a property
function buyProperty(source, propertyId)
    if not PlayerData[source] or not Properties[propertyId] then return false end
    if Properties[propertyId].OwnerID ~= 0 then return false end
    
    local price = Properties[propertyId].Price
    if PlayerData[source].Money < price then
        TriggerClientEvent('chatMessage', source, "[PROPERTY]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        UPDATE `properties` SET `OwnerID` = @ownerId WHERE `ID` = @propertyId
    ]]

    MySQL.Async.execute(query, {
        ['@ownerId'] = characterId,
        ['@propertyId'] = propertyId
    }, function(rows, affected)
        if affected > 0 then
            PlayerData[source].Money = PlayerData[source].Money - price
            Properties[propertyId].OwnerID = characterId
            
            TriggerClientEvent('chatMessage', source, "[PROPERTY]", { 0, 255, 0 }, 
                ("You bought %s for $%d"):format(Properties[propertyId].Name, price))
            TriggerClientEvent('scrp:updateProperties', -1, Properties)
        end
    end)
end
