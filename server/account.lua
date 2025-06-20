-- server/account.lua
-- Merged Account & Character Management System
-- Combines secure authentication with a professional character selection system.

-- =============================================================================
-- >> PLACEHOLDERS & CORE GLOBALS
-- =============================================================================

-- Ensure these tables are initialized in your core server files.
PlayerData = PlayerData or {}
LoggedInPlayers = LoggedInPlayers or {}

-- =============================================================================
-- >> HELPER & NOTIFICATION FUNCTIONS (Replace with your framework's functions)
-- =============================================================================

function SendErrorMessage(source, message)
    print("Error: " .. message)
    if source then
        TriggerClientEvent('chatMessage', source, "ERROR", {255, 0, 0}, message)
    end
end

function SendWarningMessage(source, message)
    print("Warning: " .. message)
    if source then
        TriggerClientEvent('chatMessage', source, "WARNING", {255, 255, 0}, message)
    end
end

function SendSuccessMessage(source, message)
    print("Success: " .. message)
    if source then
        TriggerClientEvent('chatMessage', source, "SUCCESS", {0, 255, 0}, message)
    end
end

function SendInfoMessage(source, message)
    print("Info: " .. message)
    if source then
        TriggerClientEvent('chatMessage', source, "INFO", {255, 255, 255}, message)
    end
end

-- A formatted message function, often used for lists.
function SendFormattedMessage(source, color, prefix, message)
    -- This is a placeholder; your chat resource may have a similar function.
    local colorCodes = { WHITE = {255, 255, 255} }
    local rgb = colorCodes[color] or {255, 255, 255}
    if source then
        TriggerClientEvent('chatMessage', source, prefix, rgb, message)
    end
end

function LogAction(source, action, message)
    print("Log: " .. action .. " - " .. message)
    -- Consider logging to a file or database for persistent records.
end

function GetPlayerEndpoint(source)
    for k,v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("ip:")) == "ip:" then
            return v
        end
    end
    return "127.0.0.1"
end

function UnblockPlayerCommands(source)
    -- Placeholder function to unblock player commands after login.
    -- This is where you might remove a "login required" state from the player.
    print("Unblocking commands for player " .. source)
end

-- =============================================================================
-- >> PASSWORD HASHING (SECURITY)
-- =============================================================================

-- In a real implementation, use a proper bcrypt library for FiveM.
-- This simplified version is for demonstration purposes.
function generatePasswordHash(password, salt)
    return string.format("%x", string.crc32(password .. salt))
end

-- Generate a random salt for hashing.
function generateSalt()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local salt = ""
    for i = 1, 16 do
        local rand = math.random(1, #chars)
        salt = salt .. string.sub(chars, rand, rand)
    end
    return salt
end

-- =============================================================================
-- >> ACCOUNT MANAGEMENT
-- =============================================================================

function RegisterAccount(source, username, password, email)
    if not source or not username or not password or not email then
        SendErrorMessage(source, "Invalid parameters for registration!")
        return false
    end

    if string.len(username) < 3 or string.len(username) > 24 then
        SendErrorMessage(source, "Username must be between 3 and 24 characters long!")
        return false
    end
    
    if string.len(password) < 6 then
        SendErrorMessage(source, "Password must be at least 6 characters long!")
        return false
    end

    -- Check if account already exists
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM accounts WHERE Username = @username', {
        ['@username'] = username
    }, function(count)
        if count > 0 then
            SendErrorMessage(source, "An account with this username already exists!")
            return
        end

        -- Hash the password using the generated salt
        local salt = generateSalt()
        local passwordHash = generatePasswordHash(password, salt)

        -- Create new account
        MySQL.Async.execute('INSERT INTO accounts (Username, Password, Email, RegisterDate, LastLogin, IP, Salt) VALUES (@username, @password, @email, NOW(), NOW(), @ip, @salt)', {
            ['@username'] = username,
            ['@password'] = passwordHash,
            ['@email'] = email,
            ['@ip'] = GetPlayerEndpoint(source),
            ['@salt'] = salt
        }, function(insertId)
            if insertId then
                SendSuccessMessage(source, "Account registered successfully!")
                LogAction(source, "ACCOUNT_REGISTER", "New account created: " .. username .. " (ID: " .. insertId .. ")")
                -- Auto-login after registration for a smooth user experience
                LoginAccount(source, username, password)
            else
                SendErrorMessage(source, "Failed to create account. Please contact an administrator.")
            end
        end)
    end)
end

function LoginAccount(source, username, password)
    if not source or not username or not password then
        SendErrorMessage(source, "Invalid parameters for login!")
        return false
    end

    if PlayerData[source] and PlayerData[source].isLoggedIn then
        SendWarningMessage(source, "You are already logged in!")
        return false
    end

    MySQL.Async.fetchAll('SELECT * FROM accounts WHERE Username = @username', {
        ['@username'] = username,
    }, function(result)
        if #result > 0 then
            local accountData = result[1]

            -- Verify password against the stored hash and salt
            local passwordHash = generatePasswordHash(password, accountData.Salt)
            if passwordHash ~= accountData.Password then
                SendErrorMessage(source, "Invalid username or password!")
                LogAction(source, "ACCOUNT_LOGIN_FAIL", "Failed login (wrong password) for username: " .. username)
                return
            end

            -- Update LastLogin and IP address
            MySQL.Async.execute('UPDATE accounts SET LastLogin = NOW(), IP = @ip WHERE AccountID = @id', {
                ['@ip'] = GetPlayerEndpoint(source),
                ['@id'] = accountData.AccountID
            })

            -- Set player state
            if not PlayerData[source] then PlayerData[source] = {} end
            PlayerData[source].isLoggedIn = true
            PlayerData[source].accountData = accountData
            LoggedInPlayers[source] = true

            UnblockPlayerCommands(source)

            SendSuccessMessage(source, "Successfully logged in!")
            SendInfoMessage(source, "Welcome back, " .. username .. "!")
            LogAction(source, "ACCOUNT_LOGIN", "Successfully logged in to account: " .. username .. " (ID: " .. accountData.AccountID .. ")")

            -- Proceed to character selection
            LoadPlayerCharacters(source, accountData.AccountID)
        else
            SendErrorMessage(source, "Invalid username or password!")
            LogAction(source, "ACCOUNT_LOGIN_FAIL", "Failed login (no such user) for username: " .. username)
        end
    end)
end

-- =============================================================================
-- >> CHARACTER MANAGEMENT
-- =============================================================================

function LoadPlayerCharacters(source, accountId)
    MySQL.Async.fetchAll('SELECT * FROM characters WHERE AccountID = @accountId', {
        ['@accountId'] = accountId
    }, function(characters)
        if #characters > 0 then
            PlayerData[source].availableCharacters = characters
            SendSuccessMessage(source, "You have " .. #characters .. " character(s).")
            
            for i, char in ipairs(characters) do
                SendFormattedMessage(source, "WHITE", "", string.format("%d. %s (Level %d)", i, char.Name, char.Level))
            end
            
            SendInfoMessage(source, "Use /selectchar [number] to play, or /createchar [name] to make a new one.")
        else
            SendInfoMessage(source, "You don't have any characters yet.")
            SendInfoMessage(source, "Use /createchar [name] to create your first character.")
        end
    end)
end

function SelectCharacter(source, charIndex)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in to select a character.")
        return
    end
    
    local characters = PlayerData[source].availableCharacters
    if not characters then
        SendErrorMessage(source, "No characters available to select. Try relogging.")
        return
    end
    
    charIndex = tonumber(charIndex)
    if not charIndex or charIndex < 1 or charIndex > #characters then
        SendErrorMessage(source, "Invalid character number. Please choose from the list.")
        return
    end
    
    local selectedChar = characters[charIndex]
    
    -- Placeholder for your function that loads all character-specific data
    -- (inventory, position, stats, etc.) and spawns the player.
    -- loadPlayerData(source, selectedChar.CharacterID)
    print("Placeholder: Would now load all data for CharacterID " .. selectedChar.CharacterID)
    
    SendSuccessMessage(source, "You have selected your character: " .. selectedChar.Name)
    LogAction(source, "CHARACTER_SELECT", "Selected character: " .. selectedChar.Name .. " (ID: " .. selectedChar.CharacterID .. ")")
end

function CreateCharacter(source, name, age, gender, skin)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in to create a character.")
        return
    end
    
    if not name or string.len(name) < 3 or string.find(name, "_") == nil then
        SendErrorMessage(source, "Name must be 'Firstname_Lastname' and at least 3 chars long.")
        return
    end
    
    local accountId = PlayerData[source].accountData.AccountID
    
    -- Check if character name is already taken
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM characters WHERE Name = @name', {
        ['@name'] = name
    }, function(count)
        if count > 0 then
            SendErrorMessage(source, "A character with this name already exists!")
            return
        end
        
        -- Placeholder for your function that inserts the new character into the DB
        -- and then likely calls loadPlayerData to spawn them in.
        -- createCharacterInDB(source, accountId, name, age, gender, skin)
        print("Placeholder: Would now create character '" .. name .. "' in the database for AccountID " .. accountId)
        SendSuccessMessage(source, "Character '" .. name .. "' created successfully!")
        LogAction(source, "CHARACTER_CREATE", "Created new character: " .. name)

        -- Refresh character list
        LoadPlayerCharacters(source, accountId)
    end)
end

-- =============================================================================
-- >> COMMAND REGISTRATION
-- =============================================================================

RegisterCommand('register', function(source, args, rawCommand)
    if #args < 3 then
        SendErrorMessage(source, "USAGE: /register [username] [password] [email]")
        return
    end
    RegisterAccount(source, args[1], args[2], args[3])
end, false)

RegisterCommand('login', function(source, args, rawCommand)
    if #args < 2 then
        SendErrorMessage(source, "USAGE: /login [username] [password]")
        return
    end
    LoginAccount(source, args[1], args[2])
end, false)

RegisterCommand('selectchar', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "USAGE: /selectchar [character number from the list]")
        return
    end
    SelectCharacter(source, tonumber(args[1]))
end, false)

RegisterCommand('createchar', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "USAGE: /createchar [Firstname_Lastname]")
        return
    end
    -- For simplicity, we only require the name. You can expand this.
    -- e.g., CreateCharacter(source, args[1], args[2], args[3], args[4])
    CreateCharacter(source, args[1]) 
end, false)

-- =============================================================================
-- >> SCRIPT LOADED MESSAGE
-- =============================================================================

print("^2[Accounts] Merged account and character system loaded successfully.^0")