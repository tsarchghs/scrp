-- Advanced Housing System for South Central Roleplay
-- Compatible with mysql-async 3.3.2 and FiveM artifact 15859
-- Author: SC:RP Development Team

-- Global variables
AdvancedHouses = {}
FurnitureItems = {}
HouseInteriors = {}
PlayerInHouse = {}
EditingFurniture = {}

-- Initialize housing database tables
function initializeAdvancedHousingTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `advanced_houses` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `OwnerID` int(11) DEFAULT 0,
            `Name` varchar(64) DEFAULT 'House',
            `ExteriorX` float NOT NULL,
            `ExteriorY` float NOT NULL,
            `ExteriorZ` float NOT NULL,
            `ExteriorA` float NOT NULL,
            `InteriorID` int(11) DEFAULT 1,
            `Price` int(11) DEFAULT 100000,
            `Locked` int(1) DEFAULT 1,
            `SafeMoney` int(11) DEFAULT 0,
            `RentPrice` int(11) DEFAULT 0,
            `ForSale` int(1) DEFAULT 0,
            `Description` varchar(255) DEFAULT 'A nice house',
            `Level` int(2) DEFAULT 1,
            `MaxFurniture` int(3) DEFAULT 50,
            `SecurityLevel` int(2) DEFAULT 1,
            `LastPaid` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `house_furniture` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `HouseID` int(11) NOT NULL,
            `FurnitureID` int(11) NOT NULL,
            `PosX` float NOT NULL,
            `PosY` float NOT NULL,
            `PosZ` float NOT NULL,
            `RotX` float DEFAULT 0.0,
            `RotY` float DEFAULT 0.0,
            `RotZ` float DEFAULT 0.0,
            `TextureID` int(11) DEFAULT 0,
            `CustomName` varchar(64) DEFAULT NULL,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`HouseID`) REFERENCES `advanced_houses`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `house_storage` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `HouseID` int(11) NOT NULL,
            `ItemName` varchar(64) NOT NULL,
            `Quantity` int(11) DEFAULT 1,
            `Data` text DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`HouseID`) REFERENCES `advanced_houses`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `house_roommates` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `HouseID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `AccessLevel` int(1) DEFAULT 1,
            `RentPaid` int(1) DEFAULT 0,
            `LastPaid` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`HouseID`) REFERENCES `advanced_houses`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `furniture_catalog` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `Model` varchar(64) NOT NULL,
            `Category` varchar(32) DEFAULT 'Misc',
            `Price` int(11) DEFAULT 1000,
            `Level` int(2) DEFAULT 1,
            `TextureOptions` int(11) DEFAULT 0,
            `IsStorage` int(1) DEFAULT 0,
            `StorageSlots` int(11) DEFAULT 0,
            `Description` varchar(255) DEFAULT 'A piece of furniture',
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    print("[SC:RP] Advanced housing tables initialized.")
    
    -- Initialize furniture catalog with default items
    initializeFurnitureCatalog()
    
    -- Initialize house interiors
    initializeHouseInteriors()
end

-- Initialize furniture catalog with default items
function initializeFurnitureCatalog()
    -- Check if catalog is already populated
    MySQL.Async.fetchAll("SELECT COUNT(*) as count FROM furniture_catalog", {}, function(result)
        if result[1].count == 0 then
            -- Furniture categories: Living Room, Bedroom, Kitchen, Bathroom, Office, Outdoor, Decoration, Storage, Misc
            
            -- Living Room
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Leather Sofa", "prop_sofa_01", "Living Room", 5000, 1, 4, 0, 0, "A comfortable leather sofa"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Coffee Table", "prop_coffee_table_01", "Living Room", 2500, 1, 2, 0, 0, "A stylish coffee table"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"TV Stand", "prop_tv_stand_01", "Living Room", 3500, 1, 3, 0, 0, "A modern TV stand"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Flat Screen TV", "prop_tv_flat_01", "Living Room", 8000, 2, 0, 0, 0, "A large flat screen TV"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Armchair", "prop_chair_04a", "Living Room", 3000, 1, 4, 0, 0, "A comfortable armchair"})
            
            -- Bedroom
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Double Bed", "prop_bed_01", "Bedroom", 7500, 1, 5, 0, 0, "A comfortable double bed"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Wardrobe", "prop_wardrobe_01", "Bedroom", 4500, 1, 3, 1, 20, "A spacious wardrobe for clothes"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Bedside Table", "prop_table_bedside", "Bedroom", 2000, 1, 2, 1, 5, "A small bedside table with storage"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Dresser", "prop_dresser_01", "Bedroom", 3500, 1, 3, 1, 15, "A dresser for your clothes"})
            
            -- Kitchen
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Kitchen Counter", "prop_kitchen_counter_01", "Kitchen", 4000, 1, 3, 0, 0, "A modern kitchen counter"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Refrigerator", "prop_fridge_01", "Kitchen", 6000, 2, 2, 1, 25, "A large refrigerator"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Dining Table", "prop_table_04", "Kitchen", 3500, 1, 3, 0, 0, "A dining table for meals"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Dining Chair", "prop_chair_01a", "Kitchen", 1500, 1, 4, 0, 0, "A dining chair"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Microwave", "prop_microwave_1", "Kitchen", 2500, 1, 0, 0, 0, "A microwave oven"})
            
            -- Bathroom
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Bathroom Sink", "prop_sink_01", "Bathroom", 3000, 1, 2, 0, 0, "A bathroom sink"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Toilet", "prop_toilet_01", "Bathroom", 2500, 1, 0, 0, 0, "A toilet"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Shower", "prop_shower_01", "Bathroom", 4000, 2, 2, 0, 0, "A shower"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Bathroom Cabinet", "prop_cabinet_01", "Bathroom", 2000, 1, 2, 1, 10, "A bathroom cabinet for toiletries"})
            
            -- Office
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Office Desk", "prop_office_desk_01", "Office", 5000, 2, 3, 0, 0, "A professional office desk"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Office Chair", "prop_off_chair_01", "Office", 3000, 2, 4, 0, 0, "An ergonomic office chair"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Filing Cabinet", "prop_filing_01", "Office", 2500, 2, 2, 1, 15, "A filing cabinet for documents"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Computer", "prop_pc_01", "Office", 4000, 2, 0, 0, 0, "A desktop computer"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Bookshelf", "prop_bookshelf_01", "Office", 3500, 2, 3, 1, 20, "A bookshelf for your books"})
            
            -- Decoration
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Wall Art", "prop_wall_art_01", "Decoration", 2000, 1, 5, 0, 0, "Decorative wall art"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Plant", "prop_plant_int_01a", "Decoration", 1500, 1, 0, 0, 0, "A decorative indoor plant"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Floor Lamp", "prop_floor_lamp_01", "Decoration", 2500, 1, 3, 0, 0, "A stylish floor lamp"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Rug", "prop_rug_01", "Decoration", 3000, 1, 6, 0, 0, "A decorative rug"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Wall Clock", "prop_wall_clock_01", "Decoration", 1000, 1, 2, 0, 0, "A wall clock"})
            
            -- Storage
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Safe", "prop_ld_int_safe_01", "Storage", 10000, 3, 0, 1, 30, "A secure safe for valuables"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Storage Box", "prop_box_wood01a", "Storage", 2000, 1, 2, 1, 15, "A wooden storage box"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Gun Cabinet", "prop_cabinet_gun_01", "Storage", 15000, 3, 1, 1, 10, "A secure cabinet for weapons"})
            MySQL.Async.execute("INSERT INTO furniture_catalog (Name, Model, Category, Price, Level, TextureOptions, IsStorage, StorageSlots, Description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {"Drug Lab", "prop_drug_package", "Storage", 20000, 4, 0, 1, 20, "A lab for processing drugs"})
            
            print("[SC:RP] Furniture catalog initialized with default items.")
        end
    end)
end

-- Initialize house interiors
function initializeHouseInteriors()
    HouseInteriors = {
        {
            ID = 1,
            Name = "Small Apartment",
            SpawnX = 151.3, SpawnY = -1007.5, SpawnZ = -99.0, SpawnA = 0.0,
            IPL = "shell_v16mid",
            MaxFurniture = 50,
            Price = 100000,
            Description = "A small apartment with basic amenities."
        },
        {
            ID = 2,
            Name = "Medium Apartment",
            SpawnX = 265.8, SpawnY = -1007.4, SpawnZ = -101.0, SpawnA = 0.0,
            IPL = "shell_highend",
            MaxFurniture = 75,
            Price = 250000,
            Description = "A medium-sized apartment with modern design."
        },
        {
            ID = 3,
            Name = "Luxury Apartment",
            SpawnX = 117.2, SpawnY = 559.5, SpawnZ = 184.3, SpawnA = 0.0,
            IPL = "shell_highendv2",
            MaxFurniture = 100,
            Price = 500000,
            Description = "A luxury apartment with premium amenities."
        },
        {
            ID = 4,
            Name = "Small House",
            SpawnX = 346.5, SpawnY = -1012.4, SpawnZ = -99.2, SpawnA = 0.0,
            IPL = "shell_lester",
            MaxFurniture = 80,
            Price = 350000,
            Description = "A small house with a cozy atmosphere."
        },
        {
            ID = 5,
            Name = "Medium House",
            SpawnX = -14.5, SpawnY = -1440.2, SpawnZ = 31.1, SpawnA = 0.0,
            IPL = "shell_ranch",
            MaxFurniture = 120,
            Price = 750000,
            Description = "A medium-sized house with multiple rooms."
        },
        {
            ID = 6,
            Name = "Luxury House",
            SpawnX = -174.3, SpawnY = 497.5, SpawnZ = 137.7, SpawnA = 0.0,
            IPL = "shell_michael",
            MaxFurniture = 150,
            Price = 1500000,
            Description = "A luxury house with high-end finishes."
        }
    }
    
    print("[SC:RP] House interiors initialized.")
end

-- Load all houses from database
function loadHouses()
    MySQL.Async.fetchAll("SELECT * FROM advanced_houses", {}, function(houses)
        if houses then
            for _, house in ipairs(houses) do
                AdvancedHouses[house.ID] = house
                -- Load furniture for this house
                loadHouseFurniture(house.ID)
            end
            print(("[SC:RP] Loaded %s advanced houses."):format(#houses))
        end
    end)
end

-- Load furniture for a specific house
function loadHouseFurniture(houseId)
    MySQL.Async.fetchAll("SELECT * FROM house_furniture WHERE HouseID = @houseId", {
        ['@houseId'] = houseId
    }, function(furniture)
        if furniture then
            if not FurnitureItems[houseId] then
                FurnitureItems[houseId] = {}
            end
            
            for _, item in ipairs(furniture) do
                FurnitureItems[houseId][item.ID] = item
            end
            print(("[SC:RP] Loaded %s furniture items for house ID %s."):format(#furniture, houseId))
        end
    end)
end

-- Create a new house
function createHouse(exteriorX, exteriorY, exteriorZ, exteriorA, interiorId, price, name, description)
    MySQL.Async.execute("INSERT INTO advanced_houses (ExteriorX, ExteriorY, ExteriorZ, ExteriorA, InteriorID, Price, Name, Description) VALUES (@x, @y, @z, @a, @interiorId, @price, @name, @description)", {
        ['@x'] = exteriorX,
        ['@y'] = exteriorY,
        ['@z'] = exteriorZ,
        ['@a'] = exteriorA,
        ['@interiorId'] = interiorId,
        ['@price'] = price,
        ['@name'] = name,
        ['@description'] = description
    }, function(result)
        if result.insertId then
            local houseId = result.insertId
            
            -- Load the house data
            MySQL.Async.fetchAll("SELECT * FROM advanced_houses WHERE ID = @id", {
                ['@id'] = houseId
            }, function(houses)
                if houses and #houses > 0 then
                    AdvancedHouses[houseId] = houses[1]
                    FurnitureItems[houseId] = {}
                    print(("[SC:RP] Created new house with ID %s."):format(houseId))
                end
            end)
        end
    end)
end

-- Buy a house
function buyHouse(source, houseId)
    local player = PlayerData[source]
    if not player then return end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house doesn't exist.")
        return
    end
    
    if house.OwnerID ~= 0 then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house is already owned.")
        return
    end
    
    if player.Money < house.Price then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You don't have enough money to buy this house.")
        return
    end
    
    -- Update house owner
    MySQL.Async.execute("UPDATE advanced_houses SET OwnerID = @ownerId WHERE ID = @houseId", {
        ['@ownerId'] = player.CharacterID,
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].OwnerID = player.CharacterID
            
            -- Deduct money
            player.Money = player.Money - house.Price
            updatePlayerMoney(source)
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "Congratulations! You've purchased this house for $" .. house.Price .. ".")
            print(("[SC:RP] Player %s (ID: %s) bought house ID %s for $%s."):format(player.Name, player.CharacterID, houseId, house.Price))
        end
    end)
end

-- Sell a house
function sellHouse(source, houseId)
    local player = PlayerData[source]
    if not player then return end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house doesn't exist.")
        return
    end
    
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You don't own this house.")
        return
    end
    
    local sellPrice = math.floor(house.Price * 0.7) -- 70% of original price
    
    -- Update house owner
    MySQL.Async.execute("UPDATE advanced_houses SET OwnerID = 0 WHERE ID = @houseId", {
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].OwnerID = 0
            
            -- Add money
            player.Money = player.Money + sellPrice
            updatePlayerMoney(source)
            
            -- Remove all roommates
            MySQL.Async.execute("DELETE FROM house_roommates WHERE HouseID = @houseId", {
                ['@houseId'] = houseId
            })
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "You've sold your house for $" .. sellPrice .. ".")
            print(("[SC:RP] Player %s (ID: %s) sold house ID %s for $%s."):format(player.Name, player.CharacterID, houseId, sellPrice))
        end
    end)
end

-- Lock/unlock a house
function toggleHouseLock(source, houseId)
    local player = PlayerData[source]
    if not player then return end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house doesn't exist.")
        return
    end
    
    -- Check if player is owner or roommate
    if house.OwnerID ~= player.CharacterID then
        -- Check if player is a roommate
        MySQL.Async.fetchAll("SELECT * FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
            ['@houseId'] = houseId,
            ['@charId'] = player.CharacterID
        }, function(roommates)
            if not roommates or #roommates == 0 then
                TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You don't have access to this house.")
                return
            end
            
            -- Toggle lock
            toggleLock()
        end)
    else
        -- Player is owner, toggle lock
        toggleLock()
    end
    
    function toggleLock()
        local newLockState = house.Locked == 1 and 0 or 1
        local lockText = newLockState == 1 and "locked" or "unlocked"
        
        -- Update house lock state
        MySQL.Async.execute("UPDATE advanced_houses SET Locked = @locked WHERE ID = @houseId", {
            ['@locked'] = newLockState,
            ['@houseId'] = houseId
        }, function(result)
            if result.affectedRows > 0 then
                -- Update local data
                AdvancedHouses[houseId].Locked = newLockState
                
                TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "You've " .. lockText .. " the house.")
                TriggerClientEvent('scrp:updateHouseLock', -1, houseId, newLockState)
            end
        end)
    end
end

-- Enter a house
function enterHouse(source, houseId)
    local player = PlayerData[source]
    if not player then return end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house doesn't exist.")
        return
    end
    
    -- Check if house is locked
    if house.Locked == 1 then
        -- Check if player is owner or roommate
        if house.OwnerID ~= player.CharacterID then
            -- Check if player is a roommate
            MySQL.Async.fetchAll("SELECT * FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
                ['@houseId'] = houseId,
                ['@charId'] = player.CharacterID
            }, function(roommates)
                if not roommates or #roommates == 0 then
                    TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house is locked.")
                    return
                end
                
                -- Player is a roommate, allow entry
                teleportToHouseInterior(source, houseId)
            end)
        else
            -- Player is owner, allow entry
            teleportToHouseInterior(source, houseId)
        end
    else
        -- House is unlocked, allow entry
        teleportToHouseInterior(source, houseId)
    end
end

-- Teleport player to house interior
function teleportToHouseInterior(source, houseId)
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    local interior = nil
    for _, int in ipairs(HouseInteriors) do
        if int.ID == house.InteriorID then
            interior = int
            break
        end
    end
    
    if not interior then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house has an invalid interior.")
        return
    end
    
    -- Save player's exterior position
    local player = PlayerData[source]
    if player then
        player.LastPosition = {
            x = player.Position.x,
            y = player.Position.y,
            z = player.Position.z,
            heading = player.Position.heading
        }
    end
    
    -- Track that player is in this house
    PlayerInHouse[source] = houseId
    
    -- Teleport player to interior
    TriggerClientEvent('scrp:enterHouse', source, houseId, interior)
    
    -- Load furniture for client
    if FurnitureItems[houseId] then
        TriggerClientEvent('scrp:loadHouseFurniture', source, houseId, FurnitureItems[houseId])
    end
    
    print(("[SC:RP] Player %s entered house ID %s."):format(GetPlayerName(source), houseId))
end

-- Exit a house
function exitHouse(source)
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You're not in a house.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then
        -- House doesn't exist anymore, teleport to default spawn
        TriggerClientEvent('scrp:exitHouse', source, 1642.22, -2335.48, 13.54, 0.0)
        PlayerInHouse[source] = nil
        return
    end
    
    -- Teleport player to house exterior
    TriggerClientEvent('scrp:exitHouse', source, house.ExteriorX, house.ExteriorY, house.ExteriorZ, house.ExteriorA)
    PlayerInHouse[source] = nil
    
    print(("[SC:RP] Player %s exited house ID %s."):format(GetPlayerName(source), houseId))
end

-- Buy furniture
function buyFurniture(source, furnitureId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "You need to be inside a house to buy furniture.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "This house doesn't exist.")
        return
    end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "Only the house owner can buy furniture.")
        return
    end
    
    -- Get furniture info
    MySQL.Async.fetchAll("SELECT * FROM furniture_catalog WHERE ID = @id", {
        ['@id'] = furnitureId
    }, function(furniture)
        if not furniture or #furniture == 0 then
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "This furniture doesn't exist.")
            return
        end
        
        local item = furniture[1]
        
        -- Check if player has enough money
        if player.Money < item.Price then
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "You don't have enough money to buy this furniture.")
            return
        end
        
        -- Check if house has reached furniture limit
        MySQL.Async.fetchAll("SELECT COUNT(*) as count FROM house_furniture WHERE HouseID = @houseId", {
            ['@houseId'] = houseId
        }, function(result)
            if result[1].count >= house.MaxFurniture then
                TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "This house has reached its furniture limit.")
                return
            end
            
            -- Deduct money
            player.Money = player.Money - item.Price
            updatePlayerMoney(source)
            
            -- Start furniture placement
            TriggerClientEvent('scrp:startFurniturePlacement', source, item)
            EditingFurniture[source] = {
                FurnitureID = item.ID,
                Model = item.Model,
                Name = item.Name,
                IsStorage = item.IsStorage,
                StorageSlots = item.StorageSlots
            }
            
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "You've purchased " .. item.Name .. " for $" .. item.Price .. ". Place it where you want.")
        end)
    end)
end

-- Place furniture
function placeFurniture(source, posX, posY, posZ, rotX, rotY, rotZ, textureId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then return end
    
    local furnitureData = EditingFurniture[source]
    if not furnitureData then return end
    
    -- Insert furniture into database
    MySQL.Async.execute("INSERT INTO house_furniture (HouseID, FurnitureID, PosX, PosY, PosZ, RotX, RotY, RotZ, TextureID) VALUES (@houseId, @furnitureId, @posX, @posY, @posZ, @rotX, @rotY, @rotZ, @textureId)", {
        ['@houseId'] = houseId,
        ['@furnitureId'] = furnitureData.FurnitureID,
        ['@posX'] = posX,
        ['@posY'] = posY,
        ['@posZ'] = posZ,
        ['@rotX'] = rotX,
        ['@rotY'] = rotY,
        ['@rotZ'] = rotZ,
        ['@textureId'] = textureId or 0
    }, function(result)
        if result.insertId then
            local furnitureId = result.insertId
            
            -- Add to local data
            if not FurnitureItems[houseId] then
                FurnitureItems[houseId] = {}
            end
            
            FurnitureItems[houseId][furnitureId] = {
                ID = furnitureId,
                HouseID = houseId,
                FurnitureID = furnitureData.FurnitureID,
                PosX = posX,
                PosY = posY,
                PosZ = posZ,
                RotX = rotX,
                RotY = rotY,
                RotZ = rotZ,
                TextureID = textureId or 0,
                Model = furnitureData.Model,
                Name = furnitureData.Name,
                IsStorage = furnitureData.IsStorage,
                StorageSlots = furnitureData.StorageSlots
            }
            
            -- Notify all players in the house
            for playerSource, playerHouseId in pairs(PlayerInHouse) do
                if playerHouseId == houseId then
                    TriggerClientEvent('scrp:furniturePlaced', playerSource, furnitureId, FurnitureItems[houseId][furnitureId])
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "Furniture placed successfully.")
            EditingFurniture[source] = nil
        end
    end)
end

-- Move furniture
function moveFurniture(source, furnitureId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "You need to be inside a house to move furniture.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "Only the house owner can move furniture.")
        return
    end
    
    if not FurnitureItems[houseId] or not FurnitureItems[houseId][furnitureId] then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "This furniture doesn't exist.")
        return
    end
    
    local furniture = FurnitureItems[houseId][furnitureId]
    
    -- Start furniture movement
    TriggerClientEvent('scrp:startFurnitureMovement', source, furnitureId, furniture)
    EditingFurniture[source] = {
        ID = furnitureId,
        FurnitureID = furniture.FurnitureID,
        Model = furniture.Model,
        Name = furniture.Name,
        IsStorage = furniture.IsStorage,
        StorageSlots = furniture.StorageSlots
    }
    
    TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "You're now moving " .. furniture.Name .. ". Place it where you want.")
end

-- Update furniture position
function updateFurniturePosition(source, furnitureId, posX, posY, posZ, rotX, rotY, rotZ)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then return end
    
    local furnitureData = EditingFurniture[source]
    if not furnitureData or furnitureData.ID ~= furnitureId then return end
    
    -- Update furniture in database
    MySQL.Async.execute("UPDATE house_furniture SET PosX = @posX, PosY = @posY, PosZ = @posZ, RotX = @rotX, RotY = @rotY, RotZ = @rotZ WHERE ID = @id", {
        ['@posX'] = posX,
        ['@posY'] = posY,
        ['@posZ'] = posZ,
        ['@rotX'] = rotX,
        ['@rotY'] = rotY,
        ['@rotZ'] = rotZ,
        ['@id'] = furnitureId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            FurnitureItems[houseId][furnitureId].PosX = posX
            FurnitureItems[houseId][furnitureId].PosY = posY
            FurnitureItems[houseId][furnitureId].PosZ = posZ
            FurnitureItems[houseId][furnitureId].RotX = rotX
            FurnitureItems[houseId][furnitureId].RotY = rotY
            FurnitureItems[houseId][furnitureId].RotZ = rotZ
            
            -- Notify all players in the house
            for playerSource, playerHouseId in pairs(PlayerInHouse) do
                if playerHouseId == houseId then
                    TriggerClientEvent('scrp:furnitureMoved', playerSource, furnitureId, posX, posY, posZ, rotX, rotY, rotZ)
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "Furniture moved successfully.")
            EditingFurniture[source] = nil
        end
    end)
end

-- Remove furniture
function removeFurniture(source, furnitureId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "You need to be inside a house to remove furniture.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "Only the house owner can remove furniture.")
        return
    end
    
    if not FurnitureItems[houseId] or not FurnitureItems[houseId][furnitureId] then
        TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "This furniture doesn't exist.")
        return
    end
    
    local furniture = FurnitureItems[houseId][furnitureId]
    
    -- Get furniture price for refund
    MySQL.Async.fetchAll("SELECT Price FROM furniture_catalog WHERE ID = @id", {
        ['@id'] = furniture.FurnitureID
    }, function(result)
        local refundAmount = 0
        if result and #result > 0 then
            refundAmount = math.floor(result[1].Price * 0.5) -- 50% refund
        end
        
        -- Remove furniture from database
        MySQL.Async.execute("DELETE FROM house_furniture WHERE ID = @id", {
            ['@id'] = furnitureId
        }, function(deleteResult)
            if deleteResult.affectedRows > 0 then
                -- Remove from local data
                FurnitureItems[houseId][furnitureId] = nil
                
                -- Notify all players in the house
                for playerSource, playerHouseId in pairs(PlayerInHouse) do
                    if playerHouseId == houseId then
                        TriggerClientEvent('scrp:furnitureRemoved', playerSource, furnitureId)
                    end
                end
                
                -- Refund money
                if refundAmount > 0 then
                    player.Money = player.Money + refundAmount
                    updatePlayerMoney(source)
                    TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "Furniture removed. You received a refund of $" .. refundAmount .. ".")
                else
                    TriggerClientEvent('chatMessage', source, "[FURNITURE]", {0, 255, 0}, "Furniture removed successfully.")
                end
            end
        end)
    end)
end

-- Add roommate
function addRoommate(source, targetId)
    local player = PlayerData[source]
    if not player then return end
    
    local target = PlayerData[targetId]
    if not target then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Player not found.")
        return
    end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to add a roommate.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can add roommates.")
        return
    end
    
    -- Check if target is already a roommate
    MySQL.Async.fetchAll("SELECT * FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
        ['@houseId'] = houseId,
        ['@charId'] = target.CharacterID
    }, function(roommates)
        if roommates and #roommates > 0 then
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This player is already a roommate.")
            return
        end
        
        -- Add roommate
        MySQL.Async.execute("INSERT INTO house_roommates (HouseID, CharacterID) VALUES (@houseId, @charId)", {
            ['@houseId'] = houseId,
            ['@charId'] = target.CharacterID
        }, function(result)
            if result.insertId then
                TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "You've added " .. target.Name .. " as a roommate.")
                TriggerClientEvent('chatMessage', targetId, "[HOUSE]", {0, 255, 0}, "You've been added as a roommate to " .. house.Name .. ".")
            end
        end)
    end)
end

-- Remove roommate
function removeRoommate(source, targetId)
    local player = PlayerData[source]
    if not player then return end
    
    local target = PlayerData[targetId]
    if not target then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Player not found.")
        return
    end
    
    -- Get player's houses
    MySQL.Async.fetchAll("SELECT * FROM advanced_houses WHERE OwnerID = @ownerId", {
        ['@ownerId'] = player.CharacterID
    }, function(houses)
        if not houses or #houses == 0 then
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You don't own any houses.")
            return
        end
        
        local found = false
        for _, house in ipairs(houses) do
            -- Check if target is a roommate in this house
            MySQL.Async.fetchAll("SELECT * FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
                ['@houseId'] = house.ID,
                ['@charId'] = target.CharacterID
            }, function(roommates)
                if roommates and #roommates > 0 then
                    found = true
                    
                    -- Remove roommate
                    MySQL.Async.execute("DELETE FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
                        ['@houseId'] = house.ID,
                        ['@charId'] = target.CharacterID
                    }, function(result)
                        if result.affectedRows > 0 then
                            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "You've removed " .. target.Name .. " as a roommate from " .. house.Name .. ".")
                            TriggerClientEvent('chatMessage', targetId, "[HOUSE]", {255, 165, 0}, "You've been removed as a roommate from " .. house.Name .. ".")
                            
                            -- If target is in the house, kick them out
                            if PlayerInHouse[targetId] == house.ID then
                                exitHouse(targetId)
                                TriggerClientEvent('chatMessage', targetId, "[HOUSE]", {255, 0, 0}, "You've been kicked out of the house.")
                            end
                        end
                    end)
                end
            end)
        end
        
        if not found then
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This player is not a roommate in any of your houses.")
        end
    end)
end

-- Access furniture storage
function accessFurnitureStorage(source, furnitureId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then return end
    
    if not FurnitureItems[houseId] or not FurnitureItems[houseId][furnitureId] then
        TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This furniture doesn't exist.")
        return
    end
    
    local furniture = FurnitureItems[houseId][furnitureId]
    
    if furniture.IsStorage ~= 1 then
        TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This furniture doesn't have storage.")
        return
    end
    
    -- Get storage items
    MySQL.Async.fetchAll("SELECT * FROM house_storage WHERE HouseID = @houseId", {
        ['@houseId'] = houseId
    }, function(items)
        local storageItems = items or {}
        TriggerClientEvent('scrp:openFurnitureStorage', source, furnitureId, furniture.Name, storageItems, furniture.StorageSlots)
    end)
end

-- Store item in furniture
function storeItemInFurniture(source, furnitureId, itemName, quantity, data)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then return end
    
    if not FurnitureItems[houseId] or not FurnitureItems[houseId][furnitureId] then
        TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This furniture doesn't exist.")
        return
    end
    
    local furniture = FurnitureItems[houseId][furnitureId]
    
    if furniture.IsStorage ~= 1 then
        TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This furniture doesn't have storage.")
        return
    end
    
    -- Check if player has the item
    local hasItem = false
    local itemIndex = nil
    for i, item in ipairs(player.Inventory) do
        if item.ItemName == itemName and item.Quantity >= quantity then
            hasItem = true
            itemIndex = i
            break
        end
    end
    
    if not hasItem then
        TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "You don't have enough of this item.")
        return
    end
    
    -- Check if storage has space
    MySQL.Async.fetchAll("SELECT COUNT(*) as count FROM house_storage WHERE HouseID = @houseId", {
        ['@houseId'] = houseId
    }, function(result)
        if result[1].count >= furniture.StorageSlots then
            TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This storage is full.")
            return
        end
        
        -- Store item
        MySQL.Async.execute("INSERT INTO house_storage (HouseID, ItemName, Quantity, Data) VALUES (@houseId, @itemName, @quantity, @data)", {
            ['@houseId'] = houseId,
            ['@itemName'] = itemName,
            ['@quantity'] = quantity,
            ['@data'] = data or nil
        }, function(insertResult)
            if insertResult.insertId then
                -- Remove item from player inventory
                if player.Inventory[itemIndex].Quantity > quantity then
                    player.Inventory[itemIndex].Quantity = player.Inventory[itemIndex].Quantity - quantity
                else
                    table.remove(player.Inventory, itemIndex)
                end
                
                -- Update player inventory
                TriggerClientEvent('scrp:updateInventory', source, player.Inventory)
                
                -- Update storage view
                MySQL.Async.fetchAll("SELECT * FROM house_storage WHERE HouseID = @houseId", {
                    ['@houseId'] = houseId
                }, function(items)
                    local storageItems = items or {}
                    TriggerClientEvent('scrp:updateFurnitureStorage', source, storageItems)
                end)
                
                TriggerClientEvent('chatMessage', source, "[STORAGE]", {0, 255, 0}, "Item stored successfully.")
            end
        end)
    end)
end

-- Take item from furniture
function takeItemFromFurniture(source, furnitureId, storageItemId)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then return end
    
    -- Get storage item
    MySQL.Async.fetchAll("SELECT * FROM house_storage WHERE ID = @id AND HouseID = @houseId", {
        ['@id'] = storageItemId,
        ['@houseId'] = houseId
    }, function(items)
        if not items or #items == 0 then
            TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "This item doesn't exist.")
            return
        end
        
        local item = items[1]
        
        -- Add item to player inventory
        local added = addItemToInventory(source, item.ItemName, item.Quantity, item.Data)
        
        if added then
            -- Remove item from storage
            MySQL.Async.execute("DELETE FROM house_storage WHERE ID = @id", {
                ['@id'] = storageItemId
            }, function(result)
                if result.affectedRows > 0 then
                    -- Update storage view
                    MySQL.Async.fetchAll("SELECT * FROM house_storage WHERE HouseID = @houseId", {
                        ['@houseId'] = houseId
                    }, function(updatedItems)
                        local storageItems = updatedItems or {}
                        TriggerClientEvent('scrp:updateFurnitureStorage', source, storageItems)
                    end)
                    
                    TriggerClientEvent('chatMessage', source, "[STORAGE]", {0, 255, 0}, "Item taken successfully.")
                end
            end)
        else
            TriggerClientEvent('chatMessage', source, "[STORAGE]", {255, 0, 0}, "Your inventory is full.")
        end
    end)
end

-- Set house description
function setHouseDescription(source, description)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to set its description.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can set the description.")
        return
    end
    
    -- Update house description
    MySQL.Async.execute("UPDATE advanced_houses SET Description = @description WHERE ID = @houseId", {
        ['@description'] = description,
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].Description = description
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "House description updated.")
        end
    end)
end

-- Set house name
function setHouseName(source, name)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to set its name.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can set the name.")
        return
    end
    
    -- Update house name
    MySQL.Async.execute("UPDATE advanced_houses SET Name = @name WHERE ID = @houseId", {
        ['@name'] = name,
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].Name = name
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "House name updated.")
        end
    end)
end

-- Set house for sale
function setHouseForSale(source, price)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to set it for sale.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can set it for sale.")
        return
    end
    
    -- Update house sale status
    MySQL.Async.execute("UPDATE advanced_houses SET ForSale = 1, Price = @price WHERE ID = @houseId", {
        ['@price'] = price,
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].ForSale = 1
            AdvancedHouses[houseId].Price = price
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "House is now for sale for $" .. price .. ".")
        end
    end)
end

-- Cancel house sale
function cancelHouseSale(source)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to cancel its sale.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can cancel the sale.")
        return
    end
    
    -- Update house sale status
    MySQL.Async.execute("UPDATE advanced_houses SET ForSale = 0 WHERE ID = @houseId", {
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].ForSale = 0
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "House is no longer for sale.")
        end
    end)
end

-- Upgrade house
function upgradeHouse(source)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to upgrade it.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player is owner
    if house.OwnerID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "Only the house owner can upgrade the house.")
        return
    end
    
    -- Check if house is already at max level
    if house.Level >= 5 then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "This house is already at maximum level.")
        return
    end
    
    local upgradeCost = house.Level * 50000 -- Increasing cost per level
    
    if player.Money < upgradeCost then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need $" .. upgradeCost .. " to upgrade your house.")
        return
    end
    
    -- Upgrade house
    MySQL.Async.execute("UPDATE advanced_houses SET Level = Level + 1, MaxFurniture = MaxFurniture + 25, SecurityLevel = SecurityLevel + 1 WHERE ID = @houseId", {
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            AdvancedHouses[houseId].Level = AdvancedHouses[houseId].Level + 1
            AdvancedHouses[houseId].MaxFurniture = AdvancedHouses[houseId].MaxFurniture + 25
            AdvancedHouses[houseId].SecurityLevel = AdvancedHouses[houseId].SecurityLevel + 1
            
            -- Deduct money
            player.Money = player.Money - upgradeCost
            updatePlayerMoney(source)
            
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "House upgraded to level " .. AdvancedHouses[houseId].Level .. "!")
        end
    end)
end

-- Pay house rent/maintenance
function payHouseMaintenance(source)
    local player = PlayerData[source]
    if not player then return end
    
    -- Get player's houses
    MySQL.Async.fetchAll("SELECT * FROM advanced_houses WHERE OwnerID = @ownerId", {
        ['@ownerId'] = player.CharacterID
    }, function(houses)
        if not houses or #houses == 0 then
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You don't own any houses.")
            return
        end
        
        local totalCost = 0
        for _, house in ipairs(houses) do
            totalCost = totalCost + (house.Level * 1000) -- $1000 per level per week
        end
        
        if player.Money < totalCost then
            TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need $" .. totalCost .. " to pay maintenance for all your houses.")
            return
        end
        
        -- Pay maintenance
        for _, house in ipairs(houses) do
            MySQL.Async.execute("UPDATE advanced_houses SET LastPaid = NOW() WHERE ID = @houseId", {
                ['@houseId'] = house.ID
            })
        end
        
        -- Deduct money
        player.Money = player.Money - totalCost
        updatePlayerMoney(source)
        
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {0, 255, 0}, "Paid $" .. totalCost .. " maintenance for " .. #houses .. " houses.")
    end)
end

-- House alarm system
function triggerHouseAlarm(houseId, intruderSource)
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Get house owner
    MySQL.Async.fetchAll("SELECT * FROM characters WHERE ID = @ownerId", {
        ['@ownerId'] = house.OwnerID
    }, function(owners)
        if owners and #owners > 0 then
            local owner = owners[1]
            
            -- Find owner online
            for source, playerData in pairs(PlayerData) do
                if playerData.CharacterID == owner.ID then
                    TriggerClientEvent('chatMessage', source, "[ALARM]", {255, 0, 0}, "SECURITY ALERT: Someone broke into your house at " .. house.Name .. "!")
                    TriggerClientEvent('scrp:houseAlarmTriggered', source, houseId)
                    break
                end
            end
        end
    end)
    
    -- Notify nearby players
    local coords = vector3(house.ExteriorX, house.ExteriorY, house.ExteriorZ)
    for source, playerData in pairs(PlayerData) do
        if playerData.Position then
            local distance = #(vector3(playerData.Position.x, playerData.Position.y, playerData.Position.z) - coords)
            if distance <= 100.0 then
                TriggerClientEvent('scrp:playAlarmSound', source, coords)
            end
        end
    end
    
    print(("[SC:RP] House alarm triggered at house ID %s by player %s"):format(houseId, GetPlayerName(intruderSource)))
end

-- House security system
function checkHouseSecurity(source, houseId)
    local player = PlayerData[source]
    if not player then return end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Check if player has access
    if house.OwnerID == player.CharacterID then
        return true -- Owner has access
    end
    
    -- Check if player is a roommate
    MySQL.Async.fetchAll("SELECT * FROM house_roommates WHERE HouseID = @houseId AND CharacterID = @charId", {
        ['@houseId'] = houseId,
        ['@charId'] = player.CharacterID
    }, function(roommates)
        if roommates and #roommates > 0 then
            return true -- Roommate has access
        else
            -- Unauthorized access - trigger alarm
            if house.SecurityLevel > 1 then
                triggerHouseAlarm(houseId, source)
            end
            return false
        end
    end)
end

-- Initialize advanced housing system
function initializeAdvancedHousing()
    initializeAdvancedHousingTables()
    loadHouses()
    
    -- Set up maintenance check timer (every hour)
    SetTimeout(3600000, function()
        checkHouseMaintenance()
    end)
    
    print("[SC:RP] Advanced housing system initialized.")
end

-- Check house maintenance (automated)
function checkHouseMaintenance()
    MySQL.Async.fetchAll("SELECT * FROM advanced_houses WHERE OwnerID > 0 AND DATEDIFF(NOW(), LastPaid) > 7", {}, function(houses)
        if houses then
            for _, house in ipairs(houses) do
                -- House maintenance is overdue
                MySQL.Async.fetchAll("SELECT * FROM characters WHERE ID = @ownerId", {
                    ['@ownerId'] = house.OwnerID
                }, function(owners)
                    if owners and #owners > 0 then
                        local owner = owners[1]
                        
                        -- Find owner online and notify
                        for source, playerData in pairs(PlayerData) do
                            if playerData.CharacterID == owner.ID then
                                TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 165, 0}, "WARNING: Your house '" .. house.Name .. "' maintenance is overdue!")
                                break
                            end
                        end
                        
                        -- If overdue for more than 14 days, repossess house
                        MySQL.Async.fetchAll("SELECT DATEDIFF(NOW(), LastPaid) as days FROM advanced_houses WHERE ID = @houseId", {
                            ['@houseId'] = house.ID
                        }, function(result)
                            if result and result[1].days > 14 then
                                -- Repossess house
                                MySQL.Async.execute("UPDATE advanced_houses SET OwnerID = 0, ForSale = 1 WHERE ID = @houseId", {
                                    ['@houseId'] = house.ID
                                })
                                
                                -- Remove all furniture and storage
                                MySQL.Async.execute("DELETE FROM house_furniture WHERE HouseID = @houseId", {
                                    ['@houseId'] = house.ID
                                })
                                MySQL.Async.execute("DELETE FROM house_storage WHERE HouseID = @houseId", {
                                    ['@houseId'] = house.ID
                                })
                                MySQL.Async.execute("DELETE FROM house_roommates WHERE HouseID = @houseId", {
                                    ['@houseId'] = house.ID
                                })
                                
                                -- Update local data
                                if AdvancedHouses[house.ID] then
                                    AdvancedHouses[house.ID].OwnerID = 0
                                    AdvancedHouses[house.ID].ForSale = 1
                                    FurnitureItems[house.ID] = {}
                                end
                                
                                print(("[SC:RP] House ID %s repossessed due to unpaid maintenance."):format(house.ID))
                            end
                        end)
                    end
                end)
            end
        end
    end)
    
    -- Schedule next check
    SetTimeout(3600000, function()
        checkHouseMaintenance()
    end)
end

-- Event handlers
RegisterServerEvent('scrp:buyHouse')
AddEventHandler('scrp:buyHouse', function(houseId)
    buyHouse(source, houseId)
end)

RegisterServerEvent('scrp:sellHouse')
AddEventHandler('scrp:sellHouse', function(houseId)
    sellHouse(source, houseId)
end)

RegisterServerEvent('scrp:enterHouse')
AddEventHandler('scrp:enterHouse', function(houseId)
    enterHouse(source, houseId)
end)

RegisterServerEvent('scrp:exitHouse')
AddEventHandler('scrp:exitHouse', function()
    exitHouse(source)
end)

RegisterServerEvent('scrp:toggleHouseLock')
AddEventHandler('scrp:toggleHouseLock', function(houseId)
    toggleHouseLock(source, houseId)
end)

RegisterServerEvent('scrp:buyFurniture')
AddEventHandler('scrp:buyFurniture', function(furnitureId)
    buyFurniture(source, furnitureId)
end)

RegisterServerEvent('scrp:placeFurniture')
AddEventHandler('scrp:placeFurniture', function(posX, posY, posZ, rotX, rotY, rotZ, textureId)
    placeFurniture(source, posX, posY, posZ, rotX, rotY, rotZ, textureId)
end)

RegisterServerEvent('scrp:moveFurniture')
AddEventHandler('scrp:moveFurniture', function(furnitureId)
    moveFurniture(source, furnitureId)
end)

RegisterServerEvent('scrp:updateFurniturePosition')
AddEventHandler('scrp:updateFurniturePosition', function(furnitureId, posX, posY, posZ, rotX, rotY, rotZ)
    updateFurniturePosition(source, furnitureId, posX, posY, posZ, rotX, rotY, rotZ)
end)

RegisterServerEvent('scrp:removeFurniture')
AddEventHandler('scrp:removeFurniture', function(furnitureId)
    removeFurniture(source, furnitureId)
end)

RegisterServerEvent('scrp:addRoommate')
AddEventHandler('scrp:addRoommate', function(targetId)
    addRoommate(source, targetId)
end)

RegisterServerEvent('scrp:removeRoommate')
AddEventHandler('scrp:removeRoommate', function(targetId)
    removeRoommate(source, targetId)
end)

RegisterServerEvent('scrp:accessFurnitureStorage')
AddEventHandler('scrp:accessFurnitureStorage', function(furnitureId)
    accessFurnitureStorage(source, furnitureId)
end)

RegisterServerEvent('scrp:storeItemInFurniture')
AddEventHandler('scrp:storeItemInFurniture', function(furnitureId, itemName, quantity, data)
    storeItemInFurniture(source, furnitureId, itemName, quantity, data)
end)

RegisterServerEvent('scrp:takeItemFromFurniture')
AddEventHandler('scrp:takeItemFromFurniture', function(furnitureId, storageItemId)
    takeItemFromFurniture(source, furnitureId, storageItemId)
end)

RegisterServerEvent('scrp:upgradeHouse')
AddEventHandler('scrp:upgradeHouse', function()
    upgradeHouse(source)
end)

RegisterServerEvent('scrp:payHouseMaintenance')
AddEventHandler('scrp:payHouseMaintenance', function()
    payHouseMaintenance(source)
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeAdvancedHousing()
    end
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    if PlayerInHouse[source] then
        PlayerInHouse[source] = nil
    end
    if EditingFurniture[source] then
        EditingFurniture[source] = nil
    end
end)
