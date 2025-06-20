-- Enhanced UI System for Logged-in Users
-- Provides advanced HUD elements and interactive features

local EnhancedUI = {
    isVisible = false,
    playerData = {},
    jobData = {},
    currentActivity = nil,
    hudElements = {
        minimap = true,
        speedometer = true,
        jobProgress = true,
        notifications = true,
        playerStatus = true
    }
}

-- Initialize enhanced UI
function initializeEnhancedUI()
    -- Set up HUD elements
    setupSpeedometer()
    setupJobProgressHUD()
    setupNotificationSystem()
    setupPlayerStatusHUD()
    
    print("[SC:RP] Enhanced UI initialized")
end

-- Setup speedometer (as shown in the image)
function setupSpeedometer()
    CreateThread(function()
        while true do
            Wait(100)
            
            if EnhancedUI.isVisible and EnhancedUI.hudElements.speedometer then
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                    local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                    local fuel = GetVehicleFuelLevel(vehicle)
                    local engine = GetIsVehicleEngineRunning(vehicle)
                    local lights = GetVehicleLightsState(vehicle)
                    
                    -- Send data to NUI
                    SendNUIMessage({
                        type = "updateSpeedometer",
                        speed = math.floor(speed),
                        fuel = math.floor(fuel),
                        engine = engine,
                        lights = lights,
                        gear = GetVehicleCurrentGear(vehicle)
                    })
                else
                    -- Hide speedometer when not in vehicle
                    SendNUIMessage({
                        type = "hideSpeedometer"
                    })
                end
            end
        end
    end)
end

-- Setup job progress HUD
function setupJobProgressHUD()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if EnhancedUI.isVisible and EnhancedUI.hudElements.jobProgress and EnhancedUI.currentActivity then
                SendNUIMessage({
                    type = "updateJobProgress",
                    activity = EnhancedUI.currentActivity
                })
            end
        end
    end)
end

-- Setup notification system
function setupNotificationSystem()
    -- Enhanced notification display
end

-- Setup player status HUD
function setupPlayerStatusHUD()
    CreateThread(function()
        while true do
            Wait(5000) -- Update every 5 seconds
            
            if EnhancedUI.isVisible and EnhancedUI.hudElements.playerStatus then
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                local armor = GetPedArmour(ped)
                local stamina = GetPlayerStamina(PlayerId())
                
                SendNUIMessage({
                    type = "updatePlayerStatus",
                    health = health,
                    armor = armor,
                    stamina = stamina,
                    money = EnhancedUI.playerData.money or 0,
                    bank = EnhancedUI.playerData.bank or 0
                })
            end
        end
    end)
end

-- Event handlers
RegisterNetEvent('scrp:updateAuthStatus')
AddEventHandler('scrp:updateAuthStatus', function(authData)
    EnhancedUI.isVisible = authData.isLoggedIn
    
    if authData.isLoggedIn then
        SendNUIMessage({
            type = "showEnhancedHUD",
            authData = authData
        })
    else
        SendNUIMessage({
            type = "hideEnhancedHUD"
        })
    end
end)

RegisterNetEvent('scrp:startJobActivity')
AddEventHandler('scrp:startJobActivity', function(activityData)
    EnhancedUI.currentActivity = activityData
    
    SendNUIMessage({
        type = "startJobActivity",
        activity = activityData
    })
end)

RegisterNetEvent('scrp:updateJobProgress')
AddEventHandler('scrp:updateJobProgress', function(activityId, progress)
    if EnhancedUI.currentActivity and EnhancedUI.currentActivity.activityId == activityId then
        EnhancedUI.currentActivity.progress = progress
        
        SendNUIMessage({
            type = "updateJobProgress",
            activityId = activityId,
            progress = progress
        })
    end
end)

RegisterNetEvent('scrp:jobActivityCompleted')
AddEventHandler('scrp:jobActivityCompleted', function(results)
    EnhancedUI.currentActivity = nil
    
    SendNUIMessage({
        type = "jobActivityCompleted",
        results = results
    })
    
    -- Show completion notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString("Job activity completed! Check your progress.")
    DrawNotification(false, false)
end)

RegisterNetEvent('scrp:jobRewardUnlocked')
AddEventHandler('scrp:jobRewardUnlocked', function(rewardData)
    SendNUIMessage({
        type = "showRewardNotification",
        reward = rewardData
    })
    
    -- Play reward sound
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

-- Initialize when resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeEnhancedUI()
    end
end)

print("[SC:RP] Enhanced UI client script loaded")
