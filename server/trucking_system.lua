-- Advanced Trucking/Delivery System for SC:RP FiveM

TruckingSystem = {
    companies = {
        [1] = {
            name = "Los Santos Logistics",
            location = {x = 1240.0, y = -3170.0, z = 5.0},
            reputation = 0,
            contracts = {},
            payMultiplier = 1.0
        },
        [2] = {
            name = "San Andreas Freight",
            location = {x = -2533.0, y = 2341.0, z = 33.0},
            reputation = 0,
            contracts = {},
            payMultiplier = 1.2
        },
        [3] = {
            name = "Paleto Bay Shipping",
            location = {x = 155.0, y = 6629.0, z = 31.0},
            reputation = 0,
            contracts = {},
            payMultiplier = 0.9
        }
    },
    
    cargoTypes = {
        ["electronics"] = {name = "Electronics", value = 500, fragile = true, illegal = false},
        ["food"] = {name = "Food Supplies", value = 200, fragile = false, illegal = false},
        ["weapons"] = {name = "Weapons", value = 2000, fragile = false, illegal = true},
        ["drugs"] = {name = "Pharmaceuticals", value = 1500, fragile = true, illegal = true},
        ["fuel"] = {name = "Fuel", value = 300, fragile = false, illegal = false},
        ["construction"] = {name = "Construction Materials", value = 400, fragile = false, illegal = false},
        ["luxury"] = {name = "Luxury Goods", value = 1000, fragile = true, illegal = false},
        ["chemicals"] = {name = "Chemicals", value = 800, fragile = true, illegal = true}
    },
    
    routes = {
        [1] = {
            name = "City Circuit",
            start = {x = 1240.0, y = -3170.0, z = 5.0},
            end = {x = 150.0, y = -1040.0, z = 29.0},
            distance = 4.2,
            difficulty = 1,
            checkpoints = {
                {x = 800.0, y = -2500.0, z = 20.0},
                {x = 400.0, y = -1800.0, z = 25.0}
            }
        },
        [2] = {
            name = "Highway Haul",
            start = {x = 1240.0, y = -3170.0, z = 5.0},
            end = {x = -2533.0, y = 2341.0, z = 33.0},
            distance = 12.8,
            difficulty = 2,
            checkpoints = {
                {x = -500.0, y = -1000.0, z = 30.0},
                {x = -1500.0, y = 500.0, z = 35.0}
            }
        },
        [3] = {
            name = "Mountain Pass",
            start = {x = -2533.0, y = 2341.0, z = 33.0},
            end = {x = 155.0, y = 6629.0, z = 31.0},
            distance = 8.5,
            difficulty = 3,
            checkpoints = {
                {x = -1000.0, y = 4000.0, z = 200.0},
                {x = -200.0, y = 5500.0, z = 150.0}
            }
        }
    },
    
    activeDeliveries = {},
    driverData = {}
}

-- Initialize trucking tables
function initializeTruckingTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `trucking_companies` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `Reputation` int(11) DEFAULT 0,
            `TotalDeliveries` int(11) DEFAULT 0,
            `TotalRevenue` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `trucking_drivers` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `CompanyID` int(11) DEFAULT 0,
            `License` int(1) DEFAULT 0,
            `Experience` int(11) DEFAULT 0,
            `Reputation` int(11) DEFAULT 0,
            `TotalDeliveries` int(11) DEFAULT 0,
            `TotalEarnings` int(11) DEFAULT 0,
            `LastDelivery` datetime DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `CharacterID` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

MySQL.Async.execute([[
    CREATE TABLE IF NOT EXISTS `trucking_deliveries` (
        `ID` int(11) NOT NULL AUTO_INCREMENT,
        `DriverID` int(11) NOT NULL,
        `CompanyID` int(11) NOT NULL,
        `RouteID` int(11) NOT NULL,
        `CargoType` varchar(32) NOT NULL,
        `CargoValue` int(11) NOT NULL,
        `StartTime` datetime DEFAULT CURRENT_TIMESTAMP,
        `EndTime` datetime DEFAULT NULL,
        `Payment` int(11) DEFAULT 0,
        `Status` varchar(16) DEFAULT 'active',
        `DamagePercent` TINYINT UNSIGNED DEFAULT 0,
        PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `trucking_incidents` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `DeliveryID` int(11) NOT NULL,
            `IncidentType` varchar(32) NOT NULL,
            `Description` varchar(255) NOT NULL,
            `Penalty` int(11) DEFAULT 0,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Load driver data
function loadDriverData(source, characterId)
    local query = [[
        SELECT * FROM `trucking_drivers` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local data = rows[1]
            TruckingSystem.driverData[source] = {
                companyId = data.CompanyID,
                license = data.License == 1,
                experience = data.Experience,
                reputation = data.Reputation,
                totalDeliveries = data.TotalDeliveries,
                totalEarnings = data.TotalEarnings,
                lastDelivery = data.LastDelivery
            }
        else
            -- Create new driver record
            MySQL.query([[
                INSERT INTO `trucking_drivers` (`CharacterID`) VALUES (@characterId)
            ]], {
                ['@characterId'] = characterId
            })
            
            TruckingSystem.driverData[source] = {
                companyId = 0,
                license = false,
                experience = 0,
                reputation = 0,
                totalDeliveries = 0,
                totalEarnings = 0,
                lastDelivery = nil
            }
        end
    end)
end

-- Get trucking license
function getTruckingLicense(source)
    if not PlayerData[source] or not TruckingSystem.driverData[source] then return false end
    
    if TruckingSystem.driverData[source].license then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "You already have a trucking license!")
        return false
    end
    
    local licenseCost = 5000
    if PlayerData[source].Money < licenseCost then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, 
            ("You need $%d to get a trucking license!"):format(licenseCost))
        return false
    end
    
    -- Deduct money
    PlayerData[source].Money = PlayerData[source].Money - licenseCost
    
    -- Update license status
    TruckingSystem.driverData[source].license = true
    
    -- Update database
    MySQL.query([[
        UPDATE `trucking_drivers` SET `License` = 1 WHERE `CharacterID` = @characterId
    ]], {
        ['@characterId'] = PlayerData[source].CharacterID
    })
    
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 0, 255, 0 }, 
        "Trucking license obtained! You can now accept delivery contracts.")
    
    return true
end

-- Start delivery contract
function startDelivery(source, companyId, routeId, cargoType)
    if not PlayerData[source] or not TruckingSystem.driverData[source] then return false end
    if not TruckingSystem.driverData[source].license then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "You need a trucking license!")
        return false
    end
    
    if not TruckingSystem.companies[companyId] or not TruckingSystem.routes[routeId] or not TruckingSystem.cargoTypes[cargoType] then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "Invalid delivery parameters!")
        return false
    end
    
    -- Check if player already has active delivery
    if TruckingSystem.activeDeliveries[source] then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "You already have an active delivery!")
        return false
    end
    
    -- Check if player is in appropriate vehicle
    local ped = GetPlayerPed(source)
    if not IsPedInAnyVehicle(ped, false) then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "You must be in a truck to start a delivery!")
        return false
    end
    
    local vehicle = GetVehiclePedIsIn(ped, false)
    local vehicleClass = GetVehicleClass(vehicle)
    if vehicleClass ~= 20 then -- Commercial vehicles
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "You must be in a commercial truck!")
        return false
    end
    
    local company = TruckingSystem.companies[companyId]
    local route = TruckingSystem.routes[routeId]
    local cargo = TruckingSystem.cargoTypes[cargoType]
    
    -- Create delivery
    local deliveryId = "delivery_" .. source .. "_" .. os.time()
    TruckingSystem.activeDeliveries[source] = {
        id = deliveryId,
        companyId = companyId,
        routeId = routeId,
        cargoType = cargoType,
        cargoValue = cargo.value,
        startTime = os.time(),
        currentCheckpoint = 1,
        damage = 0,
        vehicle = vehicle,
        route = route,
        cargo = cargo
    }
    
    -- Log delivery start
    MySQL.query([[
        INSERT INTO `trucking_deliveries` (`DriverID`, `CompanyID`, `RouteID`, `CargoType`, `CargoValue`)
        VALUES (@driverId, @companyId, @routeId, @cargoType, @cargoValue)
    ]], {
        ['@driverId'] = PlayerData[source].CharacterID,
        ['@companyId'] = companyId,
        ['@routeId'] = routeId,
        ['@cargoType'] = cargoType,
        ['@cargoValue'] = cargo.value
    })
    
    -- Send delivery data to client
    TriggerClientEvent('scrp:startDelivery', source, {
        route = route,
        cargo = cargo,
        company = company
    })
    
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 0, 255, 0 }, 
        ("Delivery started: %s cargo via %s route"):format(cargo.name, route.name))
    
    -- Start delivery monitoring
    startDeliveryMonitoring(source)
    
    return true
end

-- Monitor delivery progress
function startDeliveryMonitoring(source)
    CreateThread(function()
        while TruckingSystem.activeDeliveries[source] do
            Wait(1000)
            
            local delivery = TruckingSystem.activeDeliveries[source]
            if not delivery then break end
            
            local ped = GetPlayerPed(source)
            local coords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- Check if still in delivery vehicle
            if vehicle ~= delivery.vehicle then
                failDelivery(source, "Left delivery vehicle")
                break
            end
            
            -- Check vehicle damage
            local vehicleHealth = GetEntityHealth(vehicle)
            local maxHealth = GetEntityMaxHealth(vehicle)
            local damagePercent = math.floor(((maxHealth - vehicleHealth) / maxHealth) * 100)
            
            if damagePercent > delivery.damage then
                delivery.damage = damagePercent
                
                -- Fragile cargo takes more damage
                if delivery.cargo.fragile and damagePercent > 30 then
                    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 165, 0 }, 
                        "Warning: Fragile cargo is being damaged!")
                end
                
                -- Fail delivery if too much damage
                if damagePercent > 80 then
                    failDelivery(source, "Vehicle too damaged")
                    break
                end
            end
            
            -- Check checkpoint progress
            local route = delivery.route
            local currentCheckpoint = delivery.currentCheckpoint
            
            if currentCheckpoint <= #route.checkpoints then
                local checkpoint = route.checkpoints[currentCheckpoint]
                local distance = #(coords - vector3(checkpoint.x, checkpoint.y, checkpoint.z))
                
                if distance < 50.0 then
                    delivery.currentCheckpoint = delivery.currentCheckpoint + 1
                    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 0, 255, 0 }, 
                        ("Checkpoint %d/%d reached"):format(currentCheckpoint, #route.checkpoints))
                    TriggerClientEvent('scrp:deliveryCheckpoint', source, delivery.currentCheckpoint)
                end
            else
                -- Check final destination
                local distance = #(coords - vector3(route.end.x, route.end.y, route.end.z))
                if distance < 100.0 then
                    completeDelivery(source)
                    break
                end
            end
            
            -- Random events
            if math.random(1, 1000) <= 2 then -- 0.2% chance per second
                triggerDeliveryEvent(source)
            end
        end
    end)
end

-- Complete delivery
function completeDelivery(source)
    local delivery = TruckingSystem.activeDeliveries[source]
    if not delivery then return end
    
    local route = delivery.route
    local cargo = delivery.cargo
    local company = TruckingSystem.companies[delivery.companyId]
    
    -- Calculate payment
    local basePayment = cargo.value * route.distance * 0.1
    local companyMultiplier = company.payMultiplier
    local damageMultiplier = math.max(0.5, 1.0 - (delivery.damage / 100))
    local timeBonus = 1.0 -- Could add time-based bonus
    
    local finalPayment = math.floor(basePayment * companyMultiplier * damageMultiplier * timeBonus)
    
    -- Award payment
    PlayerData[source].Money = PlayerData[source].Money + finalPayment
    
    -- Update driver stats
    local driverData = TruckingSystem.driverData[source]
    driverData.experience = driverData.experience + (route.difficulty * 10)
    driverData.reputation = driverData.reputation + (route.difficulty * 5)
    driverData.totalDeliveries = driverData.totalDeliveries + 1
    driverData.totalEarnings = driverData.totalEarnings + finalPayment
    
    -- Save to database
    MySQL.query([[
        UPDATE `trucking_deliveries` SET `EndTime` = NOW(), `Payment` = @payment, `Status` = 'completed', `DamagePercent` = @damage
        WHERE `DriverID` = @driverId AND `Status` = 'active'
    ]], {
        ['@payment'] = finalPayment,
        ['@damage'] = delivery.damage,
        ['@driverId'] = PlayerData[source].CharacterID
    })
    
    MySQL.query([[
        UPDATE `trucking_drivers` SET `Experience` = @experience, `Reputation` = @reputation,
        `TotalDeliveries` = @totalDeliveries, `TotalEarnings` = @totalEarnings, `LastDelivery` = NOW()
        WHERE `CharacterID` = @characterId
    ]], {
        ['@experience'] = driverData.experience,
        ['@reputation'] = driverData.reputation,
        ['@totalDeliveries'] = driverData.totalDeliveries,
        ['@totalEarnings'] = driverData.totalEarnings,
        ['@characterId'] = PlayerData[source].CharacterID
    })
    
    -- Notify player
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 0, 255, 0 }, 
        ("Delivery completed! Payment: $%d (Damage: %d%%)"):format(finalPayment, delivery.damage))
    
    -- Add driving skill experience
    addSkillExperience(source, "driving", route.difficulty * 25)
    
    -- Clean up
    TruckingSystem.activeDeliveries[source] = nil
    TriggerClientEvent('scrp:deliveryCompleted', source)
end

-- Fail delivery
function failDelivery(source, reason)
    local delivery = TruckingSystem.activeDeliveries[source]
    if not delivery then return end
    
    -- Log incident
    MySQL.query([[
        INSERT INTO `trucking_incidents` (`DeliveryID`, `IncidentType`, `Description`, `Penalty`)
        SELECT `ID`, @incidentType, @description, @penalty FROM `trucking_deliveries`
        WHERE `DriverID` = @driverId AND `Status` = 'active'
    ]], {
        ['@incidentType'] = "delivery_failed",
        ['@description'] = reason,
        ['@penalty'] = 1000,
        ['@driverId'] = PlayerData[source].CharacterID
    })
    
    -- Update delivery status
    MySQL.query([[
        UPDATE `trucking_deliveries` SET `Status` = 'failed' WHERE `DriverID` = @driverId AND `Status` = 'active'
    ]], {
        ['@driverId'] = PlayerData[source].CharacterID
    })
    
    -- Penalty
    PlayerData[source].Money = math.max(0, PlayerData[source].Money - 1000)
    TruckingSystem.driverData[source].reputation = math.max(0, TruckingSystem.driverData[source].reputation - 10)
    
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, 
        ("Delivery failed: %s. Penalty: $1000, -10 reputation"):format(reason))
    
    -- Clean up
    TruckingSystem.activeDeliveries[source] = nil
    TriggerClientEvent('scrp:deliveryFailed', source)
end

-- Trigger random delivery events
function triggerDeliveryEvent(source)
    local delivery = TruckingSystem.activeDeliveries[source]
    if not delivery then return end
    
    local events = {
        {
            type = "police_checkpoint",
            description = "Police checkpoint ahead!",
            action = function()
                if delivery.cargo.illegal then
                    if math.random(1, 100) <= 30 then -- 30% chance of getting caught
                        failDelivery(source, "Caught with illegal cargo")
                        return
                    end
                end
                TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 255, 0 }, 
                    "You passed the police checkpoint safely.")
            end
        },
        {
            type = "hijack_attempt",
            description = "Hijackers are trying to steal your cargo!",
            action = function()
                TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, 
                    "Hijackers spotted! Drive fast to escape!")
                -- Could spawn hostile NPCs here
            end
        },
        {
            type = "mechanical_issue",
            description = "Your truck is having mechanical issues!",
            action = function()
                local vehicle = delivery.vehicle
                SetVehicleEngineHealth(vehicle, GetVehicleEngineHealth(vehicle) - 200)
                TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 165, 0 }, 
                    "Mechanical issues! Find a mechanic or repair kit!")
            end
        }
    }
    
    local event = events[math.random(1, #events)]
    TriggerClientEvent('chatMessage', source, "[TRUCKING EVENT]", { 255, 255, 0 }, event.description)
    event.action()
end
