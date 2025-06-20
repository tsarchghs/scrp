-- SA-MP Style Chat System for FiveM
-- Professional chat handling with colors and formatting

-- Color definitions (SA-MP style)
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

-- Get color by name
function GetColor(colorName)
    return Colors[colorName] or Colors.WHITE
end

-- Send formatted message to player
function SendFormattedMessage(source, colorName, prefix, message)
    local color = GetColor(colorName)
    local formattedMessage = prefix and (prefix .. " " .. message) or message
    TriggerClientEvent('scrp:receiveFormattedMessage', source, color, formattedMessage)
end

-- Send system message
function SendSystemMessage(source, message)
    SendFormattedMessage(source, "YELLOW", "» System:", message)
end

-- Send error message
function SendErrorMessage(source, message)
    SendFormattedMessage(source, "RED", "» ERROR:", message)
end

-- Send success message
function SendSuccessMessage(source, message)
    SendFormattedMessage(source, "LIGHTGREEN", "» SUCCESS:", message)
end

-- Send info message
function SendInfoMessage(source, message)
    SendFormattedMessage(source, "LIGHTBLUE", "» INFO:", message)
end

-- Send warning message
function SendWarningMessage(source, message)
    SendFormattedMessage(source, "ORANGE", "» WARNING:", message)
end

-- Send admin message
function SendAdminMessage(source, message)
    SendFormattedMessage(source, "CYAN", "» ADMIN:", message)
end

-- Broadcast message to all players
function BroadcastMessage(colorName, prefix, message)
    TriggerClientEvent('scrp:receiveFormattedMessage', -1, GetColor(colorName), prefix and (prefix .. " " .. message) or message)
end

-- Send proximity message (local chat)
function SendProximityMessage(source, message, radius)
    radius = radius or 20.0
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local playerName = GetPlayerName(source)
    
    for targetSource, _ in pairs(PlayerData) do
        if targetSource ~= source then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetSource))
            local distance = #(playerCoords - targetCoords)
            
            if distance <= radius then
                SendFormattedMessage(targetSource, "WHITE", playerName .. " says:", message)
            end
        end
    end
    
    -- Send to sender
    SendFormattedMessage(source, "WHITE", "You say:", message)
end

-- Send whisper message
function SendWhisperMessage(source, targetSource, message)
    local playerName = GetPlayerName(source)
    local targetName = GetPlayerName(targetSource)
    
    SendFormattedMessage(targetSource, "GREY", playerName .. " whispers:", message)
    SendFormattedMessage(source, "GREY", "You whisper to " .. targetName .. ":", message)
end

-- Send shout message
function SendShoutMessage(source, message)
    local playerName = GetPlayerName(source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    
    for targetSource, _ in pairs(PlayerData) do
        if targetSource ~= source then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetSource))
            local distance = #(playerCoords - targetCoords)
            
            if distance <= 50.0 then
                SendFormattedMessage(targetSource, "YELLOW", playerName .. " shouts:", message)
            end
        end
    end
    
    SendFormattedMessage(source, "YELLOW", "You shout:", message)
end

-- Send faction message
function SendFactionMessage(factionId, senderSource, message)
    local senderName = GetPlayerName(senderSource)
    
    for targetSource, data in pairs(PlayerData) do
        if data.isLoggedIn and data.characterData and data.characterData.FactionID == factionId then
            if targetSource == senderSource then
                SendFormattedMessage(targetSource, "PURPLE", "[FACTION] You:", message)
            else
                SendFormattedMessage(targetSource, "PURPLE", "[FACTION] " .. senderName .. ":", message)
            end
        end
    end
end

-- Send admin chat message
function SendAdminChatMessage(senderSource, message)
    local senderName = GetPlayerName(senderSource)
    
    for targetSource, data in pairs(PlayerData) do
        if data.isLoggedIn and data.characterData and data.characterData.AdminLevel > 0 then
            if targetSource == senderSource then
                SendFormattedMessage(targetSource, "CYAN", "[ADMIN] You:", message)
            else
                SendFormattedMessage(targetSource, "CYAN", "[ADMIN] " .. senderName .. ":", message)
            end
        end
    end
end

-- Format money display
function FormatMoney(amount)
    return "$" .. string.format("%d", amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- Format time display
function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

-- Send player statistics
function SendPlayerStats(source)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You are not logged in!")
        return
    end
    
    local data = PlayerData[source].characterData
    if not data then
        SendErrorMessage(source, "Character data not found!")
        return
    end
    
    SendFormattedMessage(source, "LIGHTBLUE", "", "════════════ PLAYER STATISTICS ════════════")
    SendFormattedMessage(source, "WHITE", "Name:", data.Name)
    SendFormattedMessage(source, "WHITE", "Level:", tostring(data.Level))
    SendFormattedMessage(source, "WHITE", "Money:", FormatMoney(data.Money))
    SendFormattedMessage(source, "WHITE", "Bank:", FormatMoney(data.BankMoney))
    SendFormattedMessage(source, "WHITE", "Job:", data.JobName or "Unemployed")
    SendFormattedMessage(source, "WHITE", "Faction:", data.FactionName or "None")
    SendFormattedMessage(source, "WHITE", "Playing Time:", FormatTime(data.PlayingTime or 0))
    SendFormattedMessage(source, "LIGHTBLUE", "", "═══════════════════════════════════════════")
end

-- Send help information
function SendHelpInfo(source)
    SendFormattedMessage(source, "LIGHTBLUE", "", "════════════ HELP INFORMATION ════════════")
    SendFormattedMessage(source, "WHITE", "", "Basic Commands:")
    SendFormattedMessage(source, "YELLOW", "", "/stats - View your statistics")
    SendFormattedMessage(source, "YELLOW", "", "/inventory - View your inventory")
    SendFormattedMessage(source, "YELLOW", "", "/time - Check server time")
    SendFormattedMessage(source, "YELLOW", "", "/players - List online players")
    SendFormattedMessage(source, "WHITE", "", "")
    SendFormattedMessage(source, "WHITE", "", "Chat Commands:")
    SendFormattedMessage(source, "YELLOW", "", "/say [message] - Local chat")
    SendFormattedMessage(source, "YELLOW", "", "/shout [message] - Shout message")
    SendFormattedMessage(source, "YELLOW", "", "/whisper [id] [message] - Whisper to player")
    SendFormattedMessage(source, "WHITE", "", "")
    SendFormattedMessage(source, "WHITE", "", "For more commands, visit our website or Discord")
    SendFormattedMessage(source, "LIGHTBLUE", "", "═══════════════════════════════════════════")
end

print("^2[SC:RP] Chat system loaded successfully!^0")
