-- Enhanced Zone HUD System for SC:RP FiveM

local ZoneHUD = {
    isVisible = false,
    currentZone = nil,
    zones = {},
    captureProgress = 0,
    hudElements = {}
}

-- Update zone data from server
RegisterNetEvent('scrp:updateZoneHUD')
AddEventHandler('scrp:updateZoneHUD', function(zones)
    ZoneHUD.zones = zones
    createZoneBlips()
end)

-- Update capture progress
RegisterNetEvent('scrp:updateCaptureProgress')
AddEventHandler('scrp:updateCaptureProgress', function(progress)
    ZoneHUD.captureProgress = progress
end)

-- Zone event notification
RegisterNetEvent('scrp:zoneEvent')
AddEventHandler('scrp:zoneEvent', function(zoneId, event)
    -- Show event notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString(("Zone Event: %s"):format(event.description))
    DrawNotification(false, false)
    
    -- Play sound
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

-- Create zone blips
function createZoneBlips()
    -- Clear existing blips
    for _, blip in pairs(ZoneHUD.hudElements.blips or {}) do
        RemoveBlip(blip)
    end
    ZoneHUD.hudElements.blips = {}
    
    -- Create new blips
    for zoneId, zone in pairs(ZoneHUD.zones) do
        local blip = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
        
        -- Set blip properties based on zone type
        if zone.type == "gang_territory" then
            SetBlipSprite(blip, 84) -- Gang territory icon
        elseif zone.type == "business_district" then
            SetBlipSprite(blip, 475) -- Business icon
        elseif zone.type == "smuggling_zone" then
            SetBlipSprite(blip, 68) -- Smuggling icon
        elseif zone.type == "racing_zone" then
            SetBlipSprite(blip, 315) -- Racing icon
        elseif zone.type == "vice_zone" then
            SetBlipSprite(blip, 121) -- Vice icon
        elseif zone.type == "transport_hub" then
            SetBlipSprite(blip, 67) -- Transport icon
        end
        
        -- Set blip color based on control status
        if zone.controlledBy == 0 then
            SetBlipColour(blip, 0) -- White - unclaimed
        elseif zone.isBeingCaptured then
            SetBlipColour(blip, 1) -- Red - being captured
        elseif zone.isProtected then
            SetBlipColour(blip, 2) -- Green - protected
        else
            SetBlipColour(blip, 3) -- Blue - controlled
        end
        
        SetBlipScale(blip, 1.2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.name)
        EndTextCommandSetBlipName(blip)
        
        ZoneHUD.hudElements.blips[zoneId] = blip
    end
end

-- Main HUD thread
CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local currentZone = nil
        
        -- Check if player is in any zone
        for zoneId, zone in pairs(ZoneHUD.zones) do
            if isPointInZone(coords.x, coords.y, zone.points) then
                currentZone = zoneId
                break
            end
        end
        
        -- Update current zone
        if currentZone ~= ZoneHUD.currentZone then
            ZoneHUD.currentZone = currentZone
            if currentZone then
                ZoneHUD.isVisible = true
            else
                ZoneHUD.isVisible = false
                ZoneHUD.captureProgress = 0
            end
        end
        
        -- Draw HUD if in zone
        if ZoneHUD.isVisible and ZoneHUD.currentZone then
            drawZoneHUD()
        end
        
        -- Draw zone boundaries
        drawZoneBoundaries()
    end
end)

-- Draw zone HUD
function drawZoneHUD()
    local zone = ZoneHUD.zones[ZoneHUD.currentZone]
    if not zone then return end
    
    -- HUD background
    DrawRect(0.85, 0.15, 0.25, 0.25, 0, 0, 0, 180)
    DrawRect(0.85, 0.15, 0.25, 0.03, zone.color.r, zone.color.g, zone.color.b, 200)
    
    -- Zone name and type
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(zone.name)
    DrawText(0.73, 0.135)
    
    -- Zone type
    SetTextScale(0.0, 0.35)
    SetTextColour(200, 200, 200, 255)
    SetTextEntry("STRING")
    AddTextComponentString(getZoneTypeName(zone.type))
    DrawText(0.73, 0.16)
    
    -- Controller info
    local controllerText = "Unclaimed"
    local controllerColor = {255, 255, 255}
    
    if zone.controlledBy > 0 then
        controllerText = "Controlled"
        controllerColor = {0, 255, 0}
    end
    
    if zone.isBeingCaptured then
        controllerText = "Being Captured"
        controllerColor = {255, 0, 0}
    end
    
    SetTextScale(0.0, 0.4)
    SetTextColour(controllerColor[1], controllerColor[2], controllerColor[3], 255)
    SetTextEntry("STRING")
    AddTextComponentString(controllerText)
    DrawText(0.73, 0.19)
    
    -- Capture progress bar
    if zone.isBeingCaptured then
        local progressWidth = 0.2 * (ZoneHUD.captureProgress / 100)
        DrawRect(0.85, 0.23, 0.2, 0.02, 50, 50, 50, 200) -- Background
        DrawRect(0.76 + (progressWidth / 2), 0.23, progressWidth, 0.02, 255, 0, 0, 255) -- Progress
        
        -- Progress text
        SetTextScale(0.0, 0.35)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        AddTextComponentString(("Capturing: %.1f%%"):format(ZoneHUD.captureProgress))
        DrawText(0.73, 0.25)
    end
    
    -- Protection status
    if zone.isProtected then
        SetTextScale(0.0, 0.35)
        SetTextColour(0, 255, 0, 255)
        SetTextEntry("STRING")
        AddTextComponentString("PROTECTED")
        DrawText(0.73, zone.isBeingCaptured and 0.28 or 0.22)
    end
    
    -- Zone activities
    local yOffset = zone.isBeingCaptured and 0.31 or (zone.isProtected and 0.25 or 0.22)
    SetTextScale(0.0, 0.3)
    SetTextColour(180, 180, 180, 255)
    SetTextEntry("STRING")
    AddTextComponentString("Activities:")
    DrawText(0.73, yOffset)
    
    for i, activity in ipairs(zone.activities or {}) do
        if i <= 3 then -- Show max 3 activities
            SetTextEntry("STRING")
            AddTextComponentString("• " .. activity:gsub("_", " "))
            DrawText(0.74, yOffset + (i * 0.025))
        end
    end
    
    -- Instructions
    local instructionY = yOffset + 0.1
    SetTextScale(0.0, 0.3)
    SetTextColour(255, 255, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString("Press [E] for zone info")
    DrawText(0.73, instructionY)
    
    SetTextEntry("STRING")
    AddTextComponentString("Use /captureturf to capture")
    DrawText(0.73, instructionY + 0.025)
end

-- Draw zone boundaries
function drawZoneBoundaries()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for zoneId, zone in pairs(ZoneHUD.zones) do
        local distance = #(playerCoords - vector3(zone.center.x, zone.center.y, zone.center.z))
        
        if distance < 500.0 then -- Only draw nearby zones
            -- Draw zone boundary
            for i = 1, #zone.points do
                local point1 = zone.points[i]
                local point2 = zone.points[i == #zone.points and 1 or i + 1]
                
                local color = zone.color
                if zone.isBeingCaptured then
                    color = {r = 255, g = 0, b = 0, a = 150}
                elseif zone.isProtected then
                    color = {r = 0, g = 255, b = 0, a = 150}
                end
                
                -- Draw line between points
                DrawLine(point1.x, point1.y, zone.center.z - 5, 
                        point2.x, point2.y, zone.center.z - 5, 
                        color.r, color.g, color.b, color.a)
                DrawLine(point1.x, point1.y, zone.center.z + 50, 
                        point2.x, point2.y, zone.center.z + 50, 
                        color.r, color.g, color.b, color.a)
                DrawLine(point1.x, point1.y, zone.center.z - 5, 
                        point1.x, point1.y, zone.center.z + 50, 
                        color.r, color.g, color.b, color.a)
            end
            
            -- Draw zone center marker
            if distance < 200.0 then
                DrawMarker(1, zone.center.x, zone.center.y, zone.center.z - 1.0, 
                          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                          10.0, 10.0, 2.0, 
                          color.r, color.g, color.b, 100, 
                          false, true, 2, false, nil, nil, false)
            end
        end
    end
end

-- Check if point is in zone
function isPointInZone(x, y, points)
    local inside = false
    local j = #points
    
    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

-- Get zone type display name
function getZoneTypeName(zoneType)
    local typeNames = {
        ["gang_territory"] = "Gang Territory",
        ["business_district"] = "Business District",
        ["smuggling_zone"] = "Smuggling Zone",
        ["racing_zone"] = "Racing Zone",
        ["vice_zone"] = "Vice Zone",
        ["transport_hub"] = "Transport Hub"
    }
    return typeNames[zoneType] or "Unknown Zone"
end

-- Handle zone info key press
CreateThread(function()
    while true do
        Wait(0)
        
        if ZoneHUD.isVisible and ZoneHUD.currentZone then
            if IsControlJustPressed(0, 38) then -- E key
                TriggerServerEvent('scrp:requestZoneInfo', ZoneHUD.currentZone)
            end
        end
    end
end)
