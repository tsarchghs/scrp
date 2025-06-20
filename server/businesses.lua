-- Business system for SC:RP FiveM

BusinessTypes = {
    [1] = {name = "24/7 Store", basePrice = 50000, income = 500, icon = 52},
    [2] = {name = "Clothing Store", basePrice = 75000, income = 750, icon = 73},
    [3] = {name = "Restaurant", basePrice = 100000, income = 1000, icon = 50},
    [4] = {name = "Bar", basePrice = 120000, income = 1200, icon = 49},
    [5] = {name = "Gas Station", basePrice = 150000, income = 1500, icon = 361},
    [6] = {name = "Mechanic Shop", basePrice = 200000, income = 2000, icon = 446},
    [7] = {name = "Gun Store", basePrice = 250000, income = 2500, icon = 110}
}

Businesses = {}
BusinessProducts = {}

-- Initialize business tables
function initializeBusinessTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `businesses` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Type` int(2) NOT NULL,
            `Name` varchar(64) NOT NULL,
            `OwnerID` int(11) DEFAULT 0,
            `EntranceX` float NOT NULL,
            `EntranceY` float NOT NULL,
            `EntranceZ` float NOT NULL,
            `ExitX` float DEFAULT 0.0,
            `ExitY` float DEFAULT 0.0,
            `ExitZ` float DEFAULT 0.0,
            `Interior` int(11) DEFAULT 0,
            `Price` int(11) NOT NULL,
            `Till` int(11) DEFAULT 0,
            `Locked` int(1) DEFAULT 1,
            `Products` int(11) DEFAULT 100,
            `LastIncome` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `business_products` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `BusinessID` int(11) NOT NULL,
            `ProductName` varchar(32) NOT NULL,
            `ProductPrice` int(11) NOT NULL,
            `ProductStock` int(11) DEFAULT 50,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`BusinessID`) REFERENCES `businesses`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `business_employees` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `BusinessID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `Rank` int(2) DEFAULT 1,
            `Salary` int(11) DEFAULT 100,
            `HireDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`BusinessID`) REFERENCES `businesses`(`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to load all businesses
function loadBusinesses()
    local query = [[
        SELECT * FROM `businesses`
    ]]

    MySQL.query(query, {}, function(rows)
        Businesses = {}
        for i = 1, #rows do
            local business = rows[i]
            Businesses[business.ID] = {
                ID = business.ID,
                Type = business.Type,
                Name = business.Name,
                OwnerID = business.OwnerID,
                Entrance = {x = business.EntranceX, y = business.EntranceY, z = business.EntranceZ},
                Exit = {x = business.ExitX, y = business.ExitY, z = business.ExitZ},
                Interior = business.Interior,
                Price = business.Price,
                Till = business.Till,
                Locked = business.Locked,
                Products = business.Products,
                LastIncome = business.LastIncome,
                Employees = {}
            }
            
            -- Load business products
            loadBusinessProducts(business.ID)
            
            -- Load business employees
            loadBusinessEmployees(business.ID)
        end
        print(("[SC:RP] Loaded %d businesses"):format(#rows))
        
        -- Create business markers and blips
        TriggerClientEvent('scrp:updateBusinesses', -1, Businesses)
    end)
end

-- Function to load business products
function loadBusinessProducts(businessId)
    local query = [[
        SELECT * FROM `business_products` WHERE `BusinessID` = @businessId
    ]]

    MySQL.query(query, {
        ['@businessId'] = businessId
    }, function(rows)
        BusinessProducts[businessId] = {}
        for i = 1, #rows do
            local product = rows[i]
            table.insert(BusinessProducts[businessId], {
                ID = product.ID,
                Name = product.ProductName,
                Price = product.ProductPrice,
                Stock = product.ProductStock
            })
        end
    end)
end

-- Function to load business employees
function loadBusinessEmployees(businessId)
    local query = [[
        SELECT be.*, c.Name as EmployeeName FROM `business_employees` be
        JOIN `characters` c ON be.CharacterID = c.ID
        WHERE be.`BusinessID` = @businessId
    ]]

    MySQL.query(query, {
        ['@businessId'] = businessId
    }, function(rows)
        Businesses[businessId].Employees = {}
        for i = 1, #rows do
            local employee = rows[i]
            table.insert(Businesses[businessId].Employees, {
                ID = employee.ID,
                CharacterID = employee.CharacterID,
                Name = employee.EmployeeName,
                Rank = employee.Rank,
                Salary = employee.Salary,
                HireDate = employee.HireDate
            })
        end
    end)
end

-- Function to create a new business
function createBusiness(type, name, entranceX, entranceY, entranceZ, exitX, exitY, exitZ, interior, price)
    if not BusinessTypes[type] then return false end
    
    local query = [[
        INSERT INTO `businesses` (`Type`, `Name`, `EntranceX`, `EntranceY`, `EntranceZ`, 
        `ExitX`, `ExitY`, `ExitZ`, `Interior`, `Price`)
        VALUES (@type, @name, @entranceX, @entranceY, @entranceZ, @exitX, @exitY, @exitZ, @interior, @price)
    ]]

    MySQL.query(query, {
        ['@type'] = type,
        ['@name'] = name,
        ['@entranceX'] = entranceX,
        ['@entranceY'] = entranceY,
        ['@entranceZ'] = entranceZ,
        ['@exitX'] = exitX,
        ['@exitY'] = exitY,
        ['@exitZ'] = exitZ,
        ['@interior'] = interior,
        ['@price'] = price
    }, function(rows, affected)
        if affected > 0 then
            local businessId = MySQL.insertId
            
            -- Add default products based on business type
            addDefaultProducts(businessId, type)
            
            -- Reload businesses
            loadBusinesses()
            print(("[SC:RP] Business %s created with ID %d"):format(name, businessId))
        end
    end)
end

-- Function to add default products to a business
function addDefaultProducts(businessId, businessType)
    if businessType == 1 then -- 24/7 Store
        addBusinessProduct(businessId, "Water", 5)
        addBusinessProduct(businessId, "Sandwich", 10)
        addBusinessProduct(businessId, "Soda", 8)
        addBusinessProduct(businessId, "Chips", 7)
        addBusinessProduct(businessId, "Chocolate", 6)
    elseif businessType == 2 then -- Clothing Store
        addBusinessProduct(businessId, "T-Shirt", 25)
        addBusinessProduct(businessId, "Jeans", 40)
        addBusinessProduct(businessId, "Jacket", 60)
        addBusinessProduct(businessId, "Shoes", 35)
        addBusinessProduct(businessId, "Hat", 20)
    elseif businessType == 3 then -- Restaurant
        addBusinessProduct(businessId, "Burger", 15)
        addBusinessProduct(businessId, "Pizza", 20)
        addBusinessProduct(businessId, "Salad", 12)
        addBusinessProduct(businessId, "Steak", 30)
        addBusinessProduct(businessId, "Soda", 8)
    elseif businessType == 4 then -- Bar
        addBusinessProduct(businessId, "Beer", 10)
        addBusinessProduct(businessId, "Whiskey", 20)
        addBusinessProduct(businessId, "Vodka", 15)
        addBusinessProduct(businessId, "Wine", 25)
        addBusinessProduct(businessId, "Snacks", 5)
    elseif businessType == 5 then -- Gas Station
        addBusinessProduct(businessId, "Fuel", 5)
        addBusinessProduct(businessId, "Repair Kit", 50)
        addBusinessProduct(businessId, "Water", 5)
        addBusinessProduct(businessId, "Snacks", 7)
        addBusinessProduct(businessId, "Map", 10)
    elseif businessType == 6 then -- Mechanic Shop
        addBusinessProduct(businessId, "Repair", 100)
        addBusinessProduct(businessId, "Paint Job", 200)
        addBusinessProduct(businessId, "Tune-Up", 300)
        addBusinessProduct(businessId, "Wheels", 250)
        addBusinessProduct(businessId, "Nitro", 500)
    elseif businessType == 7 then -- Gun Store
        addBusinessProduct(businessId, "Pistol", 1000)
        addBusinessProduct(businessId, "Shotgun", 2000)
        addBusinessProduct(businessId, "SMG", 3000)
        addBusinessProduct(businessId, "Rifle", 4000)
        addBusinessProduct(businessId, "Ammo", 50)
    end
end

-- Function to add a product to a business
function addBusinessProduct(businessId, productName, productPrice)
    local query = [[
        INSERT INTO `business_products` (`BusinessID`, `ProductName`, `ProductPrice`)
        VALUES (@businessId, @productName, @productPrice)
    ]]

    MySQL.query(query, {
        ['@businessId'] = businessId,
        ['@productName'] = productName,
        ['@productPrice'] = productPrice
    })
end

-- Function to buy a business
function buyBusiness(source, businessId)
    if not PlayerData[source] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= 0 then return false end
    
    local price = Businesses[businessId].Price
    if PlayerData[source].Money < price then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        UPDATE `businesses` SET `OwnerID` = @ownerId WHERE `ID` = @businessId
    ]]

    MySQL.query(query, {
        ['@ownerId'] = characterId,
        ['@businessId'] = businessId
    }, function(rows, affected)
        if affected > 0 then
            PlayerData[source].Money = PlayerData[source].Money - price
            Businesses[businessId].OwnerID = characterId
            
            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                ("You bought %s for $%d"):format(Businesses[businessId].Name, price))
            TriggerClientEvent('scrp:updateBusinesses', -1, Businesses)
        end
    end)
end

-- Function to sell a business
function sellBusiness(source, businessId)
    if not PlayerData[source] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    local sellPrice = math.floor(Businesses[businessId].Price * 0.7) -- 70% of original price
    
    local query = [[
        UPDATE `businesses` SET `OwnerID` = 0 WHERE `ID` = @businessId
    ]]

    MySQL.query(query, {
        ['@businessId'] = businessId
    }, function(rows, affected)
        if affected > 0 then
            PlayerData[source].Money = PlayerData[source].Money + sellPrice
            Businesses[businessId].OwnerID = 0
            
            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                ("You sold %s for $%d"):format(Businesses[businessId].Name, sellPrice))
            TriggerClientEvent('scrp:updateBusinesses', -1, Businesses)
        end
    end)
end

-- Function to hire an employee
function hireEmployee(source, businessId, targetId, salary)
    if not PlayerData[source] or not PlayerData[targetId] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    local targetCharacterId = PlayerData[targetId].CharacterID
    
    -- Check if already employed
    for _, employee in ipairs(Businesses[businessId].Employees) do
        if employee.CharacterID == targetCharacterId then
            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "This person is already employed here!")
            return false
        end
    end
    
    local query = [[
        INSERT INTO `business_employees` (`BusinessID`, `CharacterID`, `Salary`)
        VALUES (@businessId, @characterId, @salary)
    ]]

    MySQL.query(query, {
        ['@businessId'] = businessId,
        ['@characterId'] = targetCharacterId,
        ['@salary'] = salary
    }, function(rows, affected)
        if affected > 0 then
            -- Reload employees
            loadBusinessEmployees(businessId)
            
            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                ("You hired %s with a salary of $%d"):format(PlayerData[targetId].Name, salary))
            TriggerClientEvent('chatMessage', targetId, "[BUSINESS]", { 0, 255, 0 }, 
                ("You were hired at %s with a salary of $%d"):format(Businesses[businessId].Name, salary))
        end
    end)
end

-- Function to fire an employee
function fireEmployee(source, businessId, employeeId)
    if not PlayerData[source] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    local employeeName = "Unknown"
    for _, employee in ipairs(Businesses[businessId].Employees) do
        if employee.ID == employeeId then
            employeeName = employee.Name
            break
        end
    end
    
    local query = [[
        DELETE FROM `business_employees` WHERE `ID` = @employeeId AND `BusinessID` = @businessId
    ]]

    MySQL.query(query, {
        ['@employeeId'] = employeeId,
        ['@businessId'] = businessId
    }, function(rows, affected)
        if affected > 0 then
            -- Reload employees
            loadBusinessEmployees(businessId)
            
            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                ("You fired %s"):format(employeeName))
                
            -- Notify the fired employee if online
            for targetId, data in pairs(PlayerData) do
                for _, employee in ipairs(Businesses[businessId].Employees) do
                    if employee.ID == employeeId and data.CharacterID == employee.CharacterID then
                        TriggerClientEvent('chatMessage', targetId, "[BUSINESS]", { 255, 0, 0 }, 
                            ("You were fired from %s"):format(Businesses[businessId].Name))
                        break
                    end
                end
            end
        end
    end)
end

-- Function to buy a product from a business
function buyProduct(source, businessId, productId, quantity)
    if not PlayerData[source] or not Businesses[businessId] or not BusinessProducts[businessId] then return false end
    
    local product = nil
    for _, p in ipairs(BusinessProducts[businessId]) do
        if p.ID == productId then
            product = p
            break
        end
    end
    
    if not product then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "Product not found!")
        return false
    end
    
    if product.Stock < quantity then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "Not enough stock!")
        return false
    end
    
    local totalPrice = product.Price * quantity
    if PlayerData[source].Money < totalPrice then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    -- Update product stock
    local query = [[
        UPDATE `business_products` SET `ProductStock` = `ProductStock` - @quantity
        WHERE `ID` = @productId
    ]]

    MySQL.query(query, {
        ['@quantity'] = quantity,
        ['@productId'] = productId
    })
    
    -- Update business till
    local query2 = [[
        UPDATE `businesses` SET `Till` = `Till` + @amount
        WHERE `ID` = @businessId
    ]]

    MySQL.query(query2, {
        ['@amount'] = totalPrice,
        ['@businessId'] = businessId
    })
    
    -- Update player money
    PlayerData[source].Money = PlayerData[source].Money - totalPrice
    
    -- Add item to player inventory (simplified)
    addItemToInventory(source, product.Name, quantity)
    
    -- Update product in memory
    for i, p in ipairs(BusinessProducts[businessId]) do
        if p.ID == productId then
            BusinessProducts[businessId][i].Stock = BusinessProducts[businessId][i].Stock - quantity
            break
        end
    end
    
    -- Update business till in memory
    Businesses[businessId].Till = Businesses[businessId].Till + totalPrice
    
    TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
        ("You bought %dx %s for $%d"):format(quantity, product.Name, totalPrice))
end

-- Function to restock products
function restockProducts(source, businessId, productId, quantity)
    if not PlayerData[source] or not Businesses[businessId] or not BusinessProducts[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    local product = nil
    for _, p in ipairs(BusinessProducts[businessId]) do
        if p.ID == productId then
            product = p
            break
        end
    end
    
    if not product then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "Product not found!")
        return false
    end
    
    local restockCost = math.floor(product.Price * 0.5 * quantity) -- 50% of selling price
    if Businesses[businessId].Till < restockCost then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "Not enough money in the till!")
        return false
    end
    
    -- Update product stock
    local query = [[
        UPDATE `business_products` SET `ProductStock` = `ProductStock` + @quantity
        WHERE `ID` = @productId
    ]]

    MySQL.query(query, {
        ['@quantity'] = quantity,
        ['@productId'] = productId
    })
    
    -- Update business till
    local query2 = [[
        UPDATE `businesses` SET `Till` = `Till` - @amount
        WHERE `ID` = @businessId
    ]]

    MySQL.query(query2, {
        ['@amount'] = restockCost,
        ['@businessId'] = businessId
    })
    
    -- Update product in memory
    for i, p in ipairs(BusinessProducts[businessId]) do
        if p.ID == productId then
            BusinessProducts[businessId][i].Stock = BusinessProducts[businessId][i].Stock + quantity
            break
        end
    end
    
    -- Update business till in memory
    Businesses[businessId].Till = Businesses[businessId].Till - restockCost
    
    TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
        ("You restocked %dx %s for $%d"):format(quantity, product.Name, restockCost))
end

-- Function to withdraw money from business till
function withdrawFromTill(source, businessId, amount)
    if not PlayerData[source] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    if Businesses[businessId].Till < amount then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "Not enough money in the till!")
        return false
    end
    
    -- Update business till
    local query = [[
        UPDATE `businesses` SET `Till` = `Till` - @amount
        WHERE `ID` = @businessId
    ]]

    MySQL.query(query, {
        ['@amount'] = amount,
        ['@businessId'] = businessId
    })
    
    -- Update player money
    PlayerData[source].Money = PlayerData[source].Money + amount
    
    -- Update business till in memory
    Businesses[businessId].Till = Businesses[businessId].Till - amount
    
    TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
        ("You withdrew $%d from the till"):format(amount))
end

-- Function to deposit money into business till
function depositToTill(source, businessId, amount)
    if not PlayerData[source] or not Businesses[businessId] then return false end
    if Businesses[businessId].OwnerID ~= PlayerData[source].CharacterID then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't own this business!")
        return false
    end
    
    if PlayerData[source].Money < amount then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, "You don't have enough money!")
        return false
    end
    
    -- Update business till
    local query = [[
        UPDATE `businesses` SET `Till` = `Till` + @amount
        WHERE `ID` = @businessId
    ]]

    MySQL.query(query, {
        ['@amount'] = amount,
        ['@businessId'] = businessId
    })
    
    -- Update player money
    PlayerData[source].Money = PlayerData[source].Money - amount
    
    -- Update business till in memory
    Businesses[businessId].Till = Businesses[businessId].Till + amount
    
    TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
        ("You deposited $%d into the till"):format(amount))
end

-- Business income timer
CreateThread(function()
    while true do
        Wait(3600000) -- 1 hour
        
        for businessId, business in pairs(Businesses) do
            if business.OwnerID > 0 then
                local income = BusinessTypes[business.Type].income
                
                -- Update business till
                local query = [[
                    UPDATE `businesses` SET `Till` = `Till` + @income, `LastIncome` = NOW()
                    WHERE `ID` = @businessId
                ]]

                MySQL.query(query, {
                    ['@income'] = income,
                    ['@businessId'] = businessId
                })
                
                -- Update business till in memory
                Businesses[businessId].Till = Businesses[businessId].Till + income
                Businesses[businessId].LastIncome = os.date("%Y-%m-%d %H:%M:%S")
                
                -- Notify owner if online
                for source, data in pairs(PlayerData) do
                    if data.CharacterID == business.OwnerID then
                        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                            ("Your business %s earned $%d"):format(business.Name, income))
                        break
                    end
                end
            end
        end
    end
end)

-- Pay employee salaries
CreateThread(function()
    while true do
        Wait(86400000) -- 24 hours
        
        for businessId, business in pairs(Businesses) do
            if business.OwnerID > 0 and #business.Employees > 0 then
                local totalSalaries = 0
                
                -- Calculate total salaries
                for _, employee in ipairs(business.Employees) do
                    totalSalaries = totalSalaries + employee.Salary
                end
                
                if business.Till >= totalSalaries then
                    -- Update business till
                    local query = [[
                        UPDATE `businesses` SET `Till` = `Till` - @amount
                        WHERE `ID` = @businessId
                    ]]

                    MySQL.query(query, {
                        ['@amount'] = totalSalaries,
                        ['@businessId'] = businessId
                    })
                    
                    -- Update business till in memory
                    Businesses[businessId].Till = Businesses[businessId].Till - totalSalaries
                    
                    -- Pay employees
                    for _, employee in ipairs(business.Employees) do
                        -- Update employee bank account
                        local query2 = [[
                            UPDATE `characters` SET `BankMoney` = `BankMoney` + @salary
                            WHERE `ID` = @characterId
                        ]]

                        MySQL.query(query2, {
                            ['@salary'] = employee.Salary,
                            ['@characterId'] = employee.CharacterID
                        })
                        
                        -- Update player data if online
                        for source, data in pairs(PlayerData) do
                            if data.CharacterID == employee.CharacterID then
                                PlayerData[source].BankMoney = PlayerData[source].BankMoney + employee.Salary
                                TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 0, 255, 0 }, 
                                    ("You received your salary of $%d from %s"):format(employee.Salary, business.Name))
                                break
                            end
                        end
                    end
                    
                    -- Notify owner
                    for source, data in pairs(PlayerData) do
                        if data.CharacterID == business.OwnerID then
                            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 255, 0 }, 
                                ("Your business %s paid $%d in employee salaries"):format(business.Name, totalSalaries))
                            break
                        end
                    end
                else
                    -- Not enough money to pay salaries
                    for source, data in pairs(PlayerData) do
                        if data.CharacterID == business.OwnerID then
                            TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
                                ("Your business %s doesn't have enough money to pay employee salaries ($%d needed)"):format(business.Name, totalSalaries))
                            break
                        end
                    end
                end
            end
        end
    end
end)
