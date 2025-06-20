-- UI management for client

local isUIOpen = false

-- Function to toggle NUI
function toggleNUI(show)
    isUIOpen = show
    SetNuiFocus(show, show)
    SendNUIMessage({
        type = show and "showUI" or "hideUI"
    })
end

-- Show character selection
function showCharacterSelection()
    toggleNUI(true)
    SendNUIMessage({
        type = "showCharacterSelection"
    })
end

-- Show inventory
RegisterNetEvent('scrp:showInventory')
AddEventHandler('scrp:showInventory', function(items)
    toggleNUI(true)
    SendNUIMessage({
        type = "showInventory",
        items = items
    })
end)

-- Show ATM
RegisterNetEvent('scrp:showATM')
AddEventHandler('scrp:showATM', function(cash, bank)
    toggleNUI(true)
    SendNUIMessage({
        type = "showATM",
        cash = cash,
        bank = bank
    })
end)

-- Show property menu
RegisterNetEvent('scrp:showPropertyMenu')
AddEventHandler('scrp:showPropertyMenu', function(propertyId, propertyData)
    toggleNUI(true)
    SendNUIMessage({
        type = "showPropertyMenu",
        propertyId = propertyId,
        propertyData = propertyData
    })
end)

-- NUI Callbacks
RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('scrp:selectCharacter', data.characterId)
    toggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('scrp:createCharacter', data.name, data.age, data.gender, data.skin)
    toggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('closeInventory', function(data, cb)
    toggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('bankTransaction', function(data, cb)
    TriggerServerEvent('scrp:bankTransaction', data.type, data.amount)
    cb('ok')
end)

RegisterNUICallback('closeATM', function(data, cb)
    toggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('buyProperty', function(data, cb)
    TriggerServerEvent('scrp:buyProperty', data.propertyId)
    cb('ok')
end)

RegisterNUICallback('enterProperty', function(data, cb)
    TriggerServerEvent('scrp:enterProperty', data.propertyId)
    cb('ok')
end)

RegisterNUICallback('closePropertyMenu', function(data, cb)
    toggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    toggleNUI(false)
    cb('ok')
end)
