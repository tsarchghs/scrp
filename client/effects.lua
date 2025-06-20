-- Client-side effects system

local currentEffects = {}
local isDead = false
local isInjured = false

-- Apply injury effects
RegisterNetEvent('scrp:applyInjury')
AddEventHandler('scrp:applyInjury', function(injuryType, severity)
    isInjured = true
    
    -- Apply visual effects based on injury
    if injuryType == 0 then -- Head injury
        SetTimecycleModifier("damage")
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", severity * 0.2)
    elseif injuryType == 1 then -- Chest injury
        SetPlayerMaxStamina(PlayerId(), 100 - (severity * 10))
    elseif injuryType == 3 or injuryType == 4 then -- Arm/Leg injury
        SetPedMoveRateOverride(PlayerPedId(), 1.0 - (severity * 0.1))
    end
    
    -- Create injury thread
    CreateThread(function()
        while isInjured do
            Wait(5000)
            local health = GetEntityHealth(PlayerPedId())
            if health > 100 then
                SetEntityHealth(PlayerPedId(), health - severity)
            end
        end
    end)
end)

-- Heal player
RegisterNetEvent('scrp:healPlayer')
AddEventHandler('scrp:healPlayer', function()
    isInjured = false
    ClearTimecycleModifier()
    SetPlayerMaxStamina(PlayerId(), 100)
    SetPedMoveRateOverride(PlayerPedId(), 1.0)
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
end)

-- Revive player
RegisterNetEvent('scrp:revivePlayer')
AddEventHandler('scrp:revivePlayer', function()
    isDead = false
    isInjured = false
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
    SetEntityHealth(playerPed, 200)
    ClearPedBloodDamage(playerPed)
    ClearTimecycleModifier()
    SetPlayerMaxStamina(PlayerId(), 100)
    SetPedMoveRateOverride(playerPed, 1.0)
end)

-- Apply drug effects
RegisterNetEvent('scrp:applyDrugEffects')
AddEventHandler('scrp:applyDrugEffects', function(drugType, effects, duration)
    currentEffects[drugType] = {
        effects = effects,
        endTime = GetGameTimer() + (duration * 1000)
    }
    
    -- Apply visual effects
    for _, effect in ipairs(effects) do
        if effect == "relaxed" then
            SetTimecycleModifier("spectator5")
        elseif effect == "energetic" then
            SetTimecycleModifier("MP_corona_switch")
            SetPlayerMaxStamina(PlayerId(), 150)
        elseif effect == "drowsy" then
            SetTimecycleModifier("drug_deadman")
        elseif effect == "paranoid" then
            SetTimecycleModifier("drug_flying_base")
            ShakeGameplayCam("DRUNK_SHAKE", 1.0)
        end
    end
    
    -- Effect duration thread
    CreateThread(function()
        Wait(duration * 1000)
        currentEffects[drugType] = nil
        
        -- Remove effects if no other drugs active
        local hasActiveEffects = false
        for _, _ in pairs(currentEffects) do
            hasActiveEffects = true
            break
        end
        
        if not hasActiveEffects then
            ClearTimecycleModifier()
            SetPlayerMaxStamina(PlayerId(), 100)
            StopGameplayCamShaking(true)
        end
    end)
end)

-- Territory war effects
RegisterNetEvent('scrp:startTerritoryWar')
AddEventHandler('scrp:startTerritoryWar', function(territoryId, warData)
    -- Create war zone effects
    PlaySoundFrontend(-1, "Air_Defences_Activated", "DLC_sum20_Business_Battle_AC_Sounds", true)
    
    -- Show notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString("Territory war started!")
    DrawNotification(false, false)
end)

RegisterNetEvent('scrp:endTerritoryWar')
AddEventHandler('scrp:endTerritoryWar', function(territoryId)
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

-- Phone effects
RegisterNetEvent('scrp:receiveMessage')
AddEventHandler('scrp:receiveMessage', function(senderNumber, message)
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
    
    SetNotificationTextEntry("STRING")
    AddTextComponentString(("SMS from %s: %s"):format(senderNumber, message))
    DrawNotification(false, false)
end)

RegisterNetEvent('scrp:incomingCall')
AddEventHandler('scrp:incomingCall', function(callerNumber, callerName)
    PlaySoundFrontend(-1, "Remote_Ring", "Phone_SoundSet_Default", true)
    
    SetNotificationTextEntry("STRING")
    AddTextComponentString(("Incoming call from %s (%s)"):format(callerName, callerNumber))
    DrawNotification(false, false)
end)
