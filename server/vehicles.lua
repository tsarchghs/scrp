-- Vehicle system

Vehicles = {}
SpawnedVehicles = {}

-- Function to load all vehicles from database
function loadVehicles()
    local query = [[
        SELECT * FROM `vehicles`
    ]]

    MySQL.query(query, {}, function(rows)
        Vehicles = {}
        for i = 1, #rows do
            local vehicle = rows[i]
            Vehicles[vehicle.ID] = {
                ID = vehicle.ID,
                Model = vehicle.Model,
                OwnerID = vehicle.OwnerID,
                FactionID = vehicle.FactionID,
                Position = {x = vehicle.PosX, y = vehicle.PosY, z = vehicle.PosZ, heading = vehicle.PosA},
                Color1 = vehicle.Color1,
                Color2 = vehicle.Color2,
                Paintjob = vehicle.Paintjob,
                Locked = vehicle.Locked,
                Fuel = vehicle.Fuel,
                Engine = vehicle.Engine,
                Lights = vehicle.Lights,
                Spawned = false
            }
        end
        print(("[SC:RP] Loaded %d vehicles"):format(#rows))
    end)
end

-- Function to create a new vehicle
function createVehicle(model, ownerId, factionId, x, y, z, heading, color1, color2)
    local query = [[
        INSERT INTO `vehicles` (`Model`, `OwnerID`, `FactionID`, `PosX`, `PosY`, `PosZ`, `PosA`, `Color1`, `Color2`)
        VALUES (@model, @ownerId, @factionId, @x, @y, @z, @heading, @color1, @color2)
    ]]

    MySQL.query(query, {
        ['@model'] = model,
        ['@ownerId'] = ownerId,
        ['@factionId'] = factionId,
        ['@x'] = x,
        ['@y'] = y,
        ['@z'] = z,
        ['@heading'] = heading,
        ['@color1'] = color1,
        ['@color2'] = color2
    }, function(rows, affected)
        if affected > 0 then
            loadVehicles() -- Reload vehicles
            print(("[SC:RP] Vehicle created with ID %d"):format(MySQL.insertId))
        end
    end)
end

-- Function to spawn a vehicle
function spawnVehicle(vehicleId)
    if not Vehicles[vehicleId] then return false end
    if Vehicles[vehicleId].Spawned then return false end

    local vehData = Vehicles[vehicleId]
    local vehicle = CreateVehicle(vehData.Model, vehData.Position.x, vehData.Position.y, vehData.Position.z, vehData.Position.heading, true, false)
    
    if DoesEntityExist(vehicle) then
        SetVehicleColours(vehicle, vehData.Color1, vehData.Color2)
        SetVehicleFuelLevel(vehicle, vehData.Fuel)
        SetVehicleEngineOn(vehicle, vehData.Engine == 1, true, false)
        SetVehicleLights(vehicle, vehData.Lights)
        SetVehicleDoorsLocked(vehicle, vehData.Locked)
        
        SpawnedVehicles[vehicle] = vehicleId
        Vehicles[vehicleId].Spawned = true
        Vehicles[vehicleId].Entity = vehicle
        
        return vehicle
    end
    return false
end

-- Function to save vehicle data
function saveVehicleData(vehicleId)
    if not Vehicles[vehicleId] or not Vehicles[vehicleId].Spawned then return end
    
    local vehicle = Vehicles[vehicleId].Entity
    if not DoesEntityExist(vehicle) then return end
    
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local fuel = GetVehicleFuelLevel(vehicle)
    local engine = GetIsVehicleEngineRunning(vehicle) and 1 or 0
    local locked = GetVehicleDoorLockStatus(vehicle)
    
    local query = [[
        UPDATE `vehicles` SET 
        `PosX` = @x, `PosY` = @y, `PosZ` = @z, `PosA` = @heading,
        `Fuel` = @fuel, `Engine` = @engine, `Locked` = @locked
        WHERE `ID` = @vehicleId
    ]]

    MySQL.query(query, {
        ['@x'] = coords.x,
        ['@y'] = coords.y,
        ['@z'] = coords.z,
        ['@heading'] = heading,
        ['@fuel'] = fuel,
        ['@engine'] = engine,
        ['@locked'] = locked,
        ['@vehicleId'] = vehicleId
    })
end
