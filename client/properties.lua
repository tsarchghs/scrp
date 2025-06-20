-- Client-side property management

local Properties = {}
local PropertyBlips = {}
local PropertyMarkers = {}

-- Update properties from server
RegisterNetEvent('scrp:updateProperties')
AddEventHandler('scrp:updateProperties', function(properties)
    Properties = properties
    createPropertyBlips()
    createPropertyMarkers()
end)

-- Create blips for properties
function createPropertyBlips()
    -- Clear existing blips
    for _, blip in pairs(PropertyBlips) do
        RemoveBlip(blip)
    end
    PropertyBlips = {}
    
    -- Create new blips
    for id, property in pairs(Properties) do
        local blip = AddBlipForCoord(property.Entrance.x, property.Entrance.y, property.Entrance.z)
        
        if property.Type == 0 then -- House
            SetBlipSprite(blip, 40)
            SetBlipColour(blip, property.OwnerID == 0 and 2 or 3)
        else -- Business
            SetBlipSprite(blip, 475)
            SetBlipColour(blip, property.OwnerID == 0 and 2 or 3)
        end
        
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(property.Name)
        EndTextCommandSetBlipName(blip)
        
        PropertyBlips[id] = blip
    end
end

-- Create markers for properties
function createPropertyMarkers()
    PropertyMarkers = {}
    for id, property in pairs(Properties) do
        PropertyMarkers[id] = property.Entrance
    end
end

-- Main thread for property interactions
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearProperty = false
        
        for id, marker in pairs(PropertyMarkers) do
            local distance = #(playerCoords - vector3(marker.x, marker.y, marker.z))
            
            if distance < 10.0 then
                nearProperty = true
                DrawMarker(1, marker.x, marker.y, marker.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 255, 255, 0, 100, false, true, 2, false, nil, nil, false)
                
                if distance < 2.0 then
                    DrawText3D(marker.x, marker.y, marker.z + 1.0, "[E] Property Menu")
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        TriggerEvent('scrp:showPropertyMenu', id, Properties[id])
                    end
                end
            end
        end
        
        if not nearProperty then
            Wait(500)
        end
    end
end)

-- Draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end
