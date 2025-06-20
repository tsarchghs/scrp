-- FiveM Client Script for South Central Roleplay
-- Professional SA-MP Style Client

local PlayerData = {}
local isLoggedIn = false
local isUIVisible = false

-- SA-MP Style colors
local Colors = {
    WHITE = {255, 255, 255},
    RED = {255, 0, 0},
    GREEN = {0, 255, 0},
    BLUE = {0, 0, 255},
    YELLOW = {255, 255, 0},
    ORANGE = {255, 165, 0},
    PURPLE = {128, 0, 128},
    PINK = {255, 192, 203},
    LIGHTBLUE = {173, 216, 230},
    LIGHTGREEN = {144, 238, 144},
    GREY = {128, 128, 128},
    BLACK = {0, 0, 0},
    CYAN = {0, 255, 255},
    MAGENTA = {255, 0, 255},
    LIME = {0, 255, 0},
    BROWN = {165, 42, 42}
}

-- Receive messages from server
RegisterNetEvent('scrp:receiveMessage')
AddEventHandler('scrp:receiveMessage', function(color, message)
    TriggerEvent('chatMessage', "", color, message)
end)

-- Receive formatted messages
RegisterNetEvent('scrp:receiveFormattedMessage')
AddEventHandler('scrp:receiveFormattedMessage', function(color, message)
    TriggerEvent('chatMessage', "", color, message)
end)

-- Set player data
RegisterNetEvent('scrp:setPlayerData')
AddEventHandler('scrp:setPlayerData', function(data)
    PlayerData = data
    isLoggedIn = true
    
    -- Set player model based on gender
    local model = GetHashKey("mp_m_freemode_01")
    if data.Gender == 0 then
        model = GetHashKey("mp_f_freemode_01")
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end
    
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- Set player position
    if data.Position then
        SetEntityCoords(PlayerPedId(), data.Position.x, data.Position.y, data.Position.z, false, false, false, true)
        SetEntityHeading(PlayerPedId(), data.Position.heading or 0.0)
    end
    
    -- Set health and armour
    SetEntityHealth(PlayerPedId(), data.Health or 200)
    SetPedArmour(PlayerPedId(), data.Armour or 0)
    
    -- Set money display
    if data.Money then
        StatSetInt(GetHashKey("MP0_WALLET_BALANCE"), data.Money, true)
    end
    
    print(("Character loaded: %s"):format(data.Name))
end)

-- Update inventory
RegisterNetEvent('scrp:updateInventory')
AddEventHandler('scrp:updateInventory', function(inventory)
    if PlayerData then
        PlayerData.Inventory = inventory
    end
end)

-- Main thread for position updates
CreateThread(function()
    while true do
        Wait(5000) -- Update every 5 seconds
        
        if isLoggedIn and PlayerData then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            -- Update position data
            PlayerData.Position = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading
            }
            
            -- Update health and armour
            PlayerData.Health = GetEntityHealth(ped)
            PlayerData.Armour = GetPedArmour(ped)
            
            -- Send position update to server
            TriggerServerEvent('scrp:updatePosition', PlayerData.Position, PlayerData.Health, PlayerData.Armour)
        end
    end
end)

-- HUD Display Thread
CreateThread(function()
    while true do
        Wait(0)
        
        if isLoggedIn and PlayerData then
            -- Display basic HUD info
            local screenW, screenH = GetActiveScreenResolution()
            
            -- Money display
            if PlayerData.Money then
                DrawText2D(0.02, 0.02, ("Money: $%d"):format(PlayerData.Money), 0.4, {255, 255, 255, 255})
            end
            
            -- Bank display
            if PlayerData.BankMoney then
                DrawText2D(0.02, 0.05, ("Bank: $%d"):format(PlayerData.BankMoney), 0.4, {255, 255, 255, 255})
            end
            
            -- Level display
            if PlayerData.Level then
                DrawText2D(0.02, 0.08, ("Level: %d"):format(PlayerData.Level), 0.4, {255, 255, 255, 255})
            end
            
            -- Job display
            if PlayerData.JobName then
                DrawText2D(0.02, 0.11, ("Job: %s"):format(PlayerData.JobName), 0.4, {255, 255, 255, 255})
            end
        else
            -- Show login prompt for non-logged in players
            local screenW, screenH = GetActiveScreenResolution()
            DrawText2D(0.5, 0.5, "~r~You must login to play!", 0.8, {255, 255, 255, 255}, true)
            DrawText2D(0.5, 0.55, "~y~Use /register [password] or /login [password]", 0.5, {255, 255, 255, 255}, true)
        end
    end
end)

-- Helper function to draw 2D text
function DrawText2D(x, y, text, scale, color, center)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(color[1], color[2], color[3], color[4] or 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    
    if center then
        SetTextCentre(true)
    end
    
    DrawText(x, y)
end

-- Basic commands
RegisterCommand('stats', function()
    if not isLoggedIn then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "You must be logged in to use this command!")
        return
    end
    
    TriggerServerEvent('scrp:requestStats')
end, false)

RegisterCommand('inventory', function()
    if not isLoggedIn then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "You must be logged in to use this command!")
        return
    end
    
    TriggerServerEvent('scrp:requestInventory')
end, false)

RegisterCommand('help', function()
    TriggerServerEvent('scrp:requestHelp')
end, false)

RegisterCommand('time', function()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    TriggerEvent('chatMessage', "", {255, 255, 0}, string.format("Server time: %02d:%02d", hour, minute))
end, false)

RegisterCommand('players', function()
    TriggerServerEvent('scrp:requestPlayerList')
end, false)

-- Chat commands
RegisterCommand('say', function(source, args, rawCommand)
    if not isLoggedIn then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "You must be logged in to use this command!")
        return
    end
    
    if #args < 1 then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "Usage: /say [message]")
        return
    end
    
    local message = table.concat(args, " ")
    TriggerServerEvent('scrp:proximityChat', message)
end, false)

RegisterCommand('shout', function(source, args, rawCommand)
    if not isLoggedIn then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "You must be logged in to use this command!")
        return
    end
    
    if #args < 1 then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "Usage: /shout [message]")
        return
    end
    
    local message = table.concat(args, " ")
    TriggerServerEvent('scrp:shoutChat', message)
end, false)

RegisterCommand('whisper', function(source, args, rawCommand)
    if not isLoggedIn then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "You must be logged in to use this command!")
        return
    end
    
    if #args < 2 then
        TriggerEvent('chatMessage', "", {255, 0, 0}, "Usage: /whisper [playerid] [message]")
        return
    end
    
    local targetId = tonumber(args[1])
    table.remove(args, 1)
    local message = table.concat(args, " ")
    
    TriggerServerEvent('scrp:whisperChat', targetId, message)
end, false)

print("^2[SC:RP] Client script loaded successfully!^0")
