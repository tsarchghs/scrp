-- Client-side teleportation system

-- Teleport player to coordinates
RegisterNetEvent('scrp:teleportPlayer')
AddEventHandler('scrp:teleportPlayer', function(x, y, z)
    local ped = PlayerPedId()
    
    -- Fade out screen
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Teleport player
    SetEntityCoords(ped, x, y, z, false, false, false, true)
    
    -- Wait for world to load
    Wait(1000)
    
    -- Fade in screen
    DoScreenFadeIn(500)
    
    -- Send confirmation
    TriggerEvent('chatMessage', "", {0, 255, 0}, "» You have been teleported!")
end)

-- Spawn vehicle
RegisterNetEvent('scrp:spawnVehicle')
AddEventHandler('scrp:spawnVehicle', function(vehicleName, x, y, z, heading)
    local vehicleHash = GetHashKey(vehicleName)
    
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "» Invalid vehicle model!")
        return
    end
    
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(500)
    end
    
    local vehicle = CreateVehicle(vehicleHash, x + 2.0, y, z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(vehicleHash)
    
    TriggerEvent('chatMessage', "", {0, 255, 0}, "» Vehicle spawned: " .. vehicleName)
end)

print("^2[SC:RP] Client teleport system loaded!^0")
