local currentSession = nil
local currentBlip = nil
local atCheckpoint = false

-- Function to draw text on the screen
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Event to start the fishing job
RegisterNetEvent('fishing:startJob')
AddEventHandler('fishing:startJob', function(session)
    currentSession = session
    CreateBlipForCheckpoint()
end)

-- Event to update the checkpoint
RegisterNetEvent('fishing:updateCheckpoint')
AddEventHandler('fishing:updateCheckpoint', function(session)
    currentSession = session
    CreateBlipForCheckpoint()
end)

-- Event to end the fishing job
RegisterNetEvent('fishing:endJob')
AddEventHandler('fishing:endJob', function()
    currentSession = nil
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
end)

-- Function to create a blip for the current checkpoint
function CreateBlipForCheckpoint()
    if currentBlip then
        RemoveBlip(currentBlip)
    end
    if currentSession and currentSession.checkpoint <= #Config.Checkpoints then
        local checkpoint = Config.Checkpoints[currentSession.checkpoint]
        currentBlip = AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z)
        SetBlipSprite(currentBlip, 1)
        SetBlipDisplay(currentBlip, 4)
        SetBlipScale(currentBlip, 1.5)
        SetBlipColour(currentBlip, 5)
        SetBlipAsShortRange(currentBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fishing Spot")
        EndTextCommandSetBlipName(currentBlip)
    end
end

-- Thread to handle drawing markers and checking distances
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        if currentSession then
            if currentSession.checkpoint <= #Config.Checkpoints then
                local checkpoint = Config.Checkpoints[currentSession.checkpoint]
                local distance = GetDistanceBetweenCoords(playerPos, checkpoint.x, checkpoint.y, checkpoint.z, true)

                if distance < 20.0 then
                    DrawMarker(1, checkpoint.x, checkpoint.y, checkpoint.z - 1.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 0, 255, 0, 100, false, true, 2, nil, nil, false)
                    if distance < 2.0 then
                        atCheckpoint = true
                        DrawText3D(checkpoint.x, checkpoint.y, checkpoint.z, "Press /fish to start fishing")
                    else
                        atCheckpoint = false
                    end
                end
            end
        else
            local distanceToStart = GetDistanceBetweenCoords(playerPos, Config.StartJobLocation.x, Config.StartJobLocation.y, Config.StartJobLocation.z, true)
            if distanceToStart < 20.0 then
                DrawMarker(1, Config.StartJobLocation.x, Config.StartJobLocation.y, Config.StartJobLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 0, 255, 0, 100, false, true, 2, nil, nil, false)
                if distanceToStart < 2.0 then
                    DrawText3D(Config.StartJobLocation.x, Config.StartJobLocation.y, Config.StartJobLocation.z, "Press /startfishing to begin")
                end
            end
        end

        local distanceToSell = GetDistanceBetweenCoords(playerPos, Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z, true)
        if distanceToSell < 20.0 then
            DrawMarker(1, Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 0, 0, 100, false, true, 2, nil, nil, false)
            if distanceToSell < 2.0 then
                DrawText3D(Config.SellLocation.x, Config.SellLocation.y, Config.SellLocation.z, "Press /sellfish to sell your fish")
            end
        end
    end
end)

-- Event to handle the fishing action
RegisterNetEvent('fishing:fish')
AddEventHandler('fishing:fish', function()
    if atCheckpoint and currentSession then
        local playerPed = PlayerPedId()
        if not IsPedInAnyVehicle(playerPed, false) then
            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_FISHING", 0, true)
            Citizen.Wait(Config.TimeToFish)
            ClearPedTasks(playerPed)
            TriggerServerEvent('fishing:giveFish')
            if currentSession then
                TriggerServerEvent('fishing:checkpointReached', currentSession.id)
            end
        else
            TriggerEvent('chat:addMessage', {
                args = {"^1ERROR", "You cannot fish while in a vehicle."}
            })
        end
    end
end)

-- Export for other resources to check if a player is fishing
function isPlayerFishing(playerId)
    return currentSession ~= nil
end