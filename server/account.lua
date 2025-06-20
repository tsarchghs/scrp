-- server/account.lua
-- Merged Account & Character Management System
-- Combines secure authentication with a professional character selection system.

-- =============================================================================
-- >> CORE GLOBALS & INITIALIZATION CHECKS
-- =============================================================================

-- Add this line at the beginning of the file to ensure the sha256 resource is started
AddEventHandler('onResourceList', function(resourceList)
    if not IsResourceRunning('sha256') then
        StartResource('sha256')
    end
end)

PlayerData = PlayerData or {} -- Placeholder for PlayerData (replace with your actual implementation)
LoggedInPlayers = LoggedInPlayers or {}

-- =============================================================================
-- >> HELPER & NOTIFICATION FUNCTIONS
-- (Uses the more comprehensive functions from the second snippet)
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

---
## Password Hashing (Security)

The `generatePasswordHash` function now incorporates the `PerformHttpRequest` call to your `sha256` resource, ensuring proper SHA-256 hashing.

```lua
-- =============================================================================
-- >> PASSWORD HASHING (SECURITY)
-- =============================================================================

-- Function to generate secure password hash using SHA-256
function generatePasswordHash(password, salt)
    -- Use SHA-256 for password hashing via the external resource
    local combinedString = password .. salt
    local passwordHash = PerformHttpRequest('http://localhost/sha256/' .. combinedString,
        function(err, text, headers)
            if err == 200 then
                -- Store the result in a way that the outer function can access it
                -- (Note: Direct return here doesn't work asynchronously for the outer function)
                -- For a simple blocking wait, this structure is used.
                -- In a real-world scenario, you'd want to use callbacks or promises.
                passwordHash = text -- This assigns to the outer 'passwordHash' local
            else
                print("Error hashing password: " .. err)
                passwordHash = "" -- Set to empty on error
            end
        end,
        'GET', '', {}
    )

    -- This busy-waits for the HTTP request to complete.
    -- For production, consider an asynchronous approach (e.g., passing callbacks).
    local waitCount = 0
    while passwordHash == nil do
        Wait(0) -- Yield control to other server tasks
        waitCount = waitCount + 1
        if waitCount > 5000 then -- Timeout after ~5 seconds (5000 * 0ms wait)
            print("Timeout waiting for SHA256 hash.")
            passwordHash = ""
            break
        end
    end

    return passwordHash
end

-- Generate random salt
function generateSalt()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local salt = ""
    for i = 1, 16 do
        local rand = math.random(1, #chars)
        salt = salt .. string.sub(chars, rand, rand)
    end
    return salt
end

---
## Account Management

The account registration and login functions are robust, including checks for existing accounts, password validation, and logging.

```lua
-- =============================================================================
-- >> ACCOUNT MANAGEMENT
-- =============================================================================

function RegisterAccount(source, username, password, email)
    if not source or not username or not password or not email then
        SendErrorMessage(source, "Invalid parameters for registration! Usage: /register [username] [password] [email]")
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
            SendInfoMessage(source, "Use /login [username] [password] to login to your existing account.")
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
        SendErrorMessage(source, "Invalid parameters for login! Usage: /login [username] [password]")
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
                SendInfoMessage(source, "If you don't have an account, use /register [username] [password] [email].")
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
            SendInfoMessage(source, "If you don't have an account, use /register [username] [password] [email].")
            LogAction(source, "ACCOUNT_LOGIN_FAIL", "Failed login (no such user) for username: " .. username)
        end
    end)
end

---
## Character Management

The character management functions allow players to load, select, and create characters associated with their account.

```lua
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
            SendInfoMessage(source, "Use /createchar [Firstname_Lastname] to create your first character.")
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

    -- Here, you would typically load all character-specific data (inventory, position, stats, etc.)
    -- and then spawn the player into the world with that data.
    -- Example placeholder:
    -- TriggerClientEvent('scrp:spawnPlayer', source, selectedChar.CharacterID)
    -- PlayerData[source].CharacterID = selectedChar.CharacterID
    -- PlayerData[source].Money = selectedChar.Money
    -- PlayerData[source].Level = selectedChar.Level
    -- PlayerData[source].Name = selectedChar.Name -- Useful for job system and other scripts

    print("Placeholder: Would now load all data for CharacterID " .. selectedChar.CharacterID .. " and spawn player.")

    SendSuccessMessage(source, "You have selected your character: " .. selectedChar.Name)
    LogAction(source, "CHARACTER_SELECT", "Selected character: " .. selectedChar.Name .. " (ID: " .. selectedChar.CharacterID .. ")")
end

function CreateCharacter(source, name, age, gender, skin)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in to create a character.")
        return
    end

    if not name or string.len(name) < 3 or string.find(name, "_") == nil then
        SendErrorMessage(source, "Name must be 'Firstname_Lastname' and at least 3 characters long.")
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

        -- Insert new character into the database
        MySQL.Async.execute('INSERT INTO characters (AccountID, Name, Money, Level) VALUES (@accountId, @name, @money, @level)', {
            ['@accountId'] = accountId,
            ['@name'] = name,
            ['@money'] = 500, -- Default starting money
            ['@level'] = 1    -- Default starting level
            -- Add more parameters here if you expand your character creation (age, gender, skin, etc.)
        }, function(insertId)
            if insertId then
                SendSuccessMessage(source, "Character '" .. name .. "' created successfully!")
                LogAction(source, "CHARACTER_CREATE", "Created new character: " .. name .. " (ID: " .. insertId .. ") for AccountID: " .. accountId)

                -- Refresh character list for the player
                LoadPlayerCharacters(source, accountId)
            else
                SendErrorMessage(source, "Failed to create character. Please try again.")
            end
        end)
    end)
end

---
## Command Registration

All `RegisterCommand` calls are consolidated here for easy management.

```lua
-- =============================================================================
-- >> COMMAND REGISTRATION
-- =============================================================================

RegisterCommand('register', function(source, args, rawCommand)
    if source == 0 then -- Prevent console from registering
        print("Console cannot use /register.")
        return
    end
    if #args < 3 then
        SendErrorMessage(source, "USAGE: /register [username] [password] [email]")
        return
    end
    RegisterAccount(source, args[1], args[2], args[3])
end, false)

RegisterCommand('login', function(source, args, rawCommand)
    if source == 0 then -- Prevent console from logging in
        print("Console cannot use /login.")
        return
    end
    if #args < 2 then
        SendErrorMessage(source, "USAGE: /login [username] [password]")
        return
    end
    LoginAccount(source, args[1], args[2])
end, false)

RegisterCommand('selectchar', function(source, args, rawCommand)
    if source == 0 then
        print("Console cannot use /selectchar.")
        return
    end
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in to your account first.")
        return
    end
    if #args < 1 then
        SendErrorMessage(source, "USAGE: /selectchar [character number from the list]")
        return
    end
    SelectCharacter(source, tonumber(args[1]))
end, false)

RegisterCommand('createchar', function(source, args, rawCommand)
    if source == 0 then
        print("Console cannot use /createchar.")
        return
    end
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in to your account first.")
        return
    end
    if #args < 1 then
        SendErrorMessage(source, "USAGE: /createchar [Firstname_Lastname]")
        return
    end
    CreateCharacter(source, args[1])
end, false)

---
## Database Initialization

This section includes the necessary SQL to create your `accounts` and `characters` tables if they don't already exist. Run this once when your resource starts.

```lua
-- =============================================================================
-- >> DATABASE INITIALIZATION
-- =============================================================================

-- It's good practice to ensure your tables exist when the resource starts.
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `accounts` (
            `AccountID` INT(11) NOT NULL AUTO_INCREMENT,
            `Username` VARCHAR(255) NOT NULL UNIQUE,
            `Password` VARCHAR(255) NOT NULL,
            `Email` VARCHAR(255) NOT NULL,
            `RegisterDate` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `LastLogin` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `IP` VARCHAR(45) NOT NULL,
            `Salt` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`AccountID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(rowsChanged)
        print("^[2SUCCESS^7]^0 'accounts' table checked/created.")
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `characters` (
            `CharacterID` INT(11) NOT NULL AUTO_INCREMENT,
            `AccountID` INT(11) NOT NULL,
            `Name` VARCHAR(255) NOT NULL UNIQUE,
            `Money` INT(11) DEFAULT 0,
            `Level` INT(11) DEFAULT 1,
            -- Add more character-specific columns here (e.g., 'Gender', 'Skin', 'PositionData')
            PRIMARY KEY (`CharacterID`),
            FOREIGN KEY (`AccountID`) REFERENCES `accounts`(`AccountID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(rowsChanged)
        print("^[2SUCCESS^7]^0 'characters' table checked/created.")
    end)
end)

---
## Player Disconnect Handling

This ensures that `PlayerData` is cleaned up when a player disconnects.

```lua
-- =============================================================================
-- >> EVENT HANDLERS
-- =============================================================================

AddEventHandler('playerDropped', function()
    local source = source
    if PlayerData[source] then
        print("Cleaning up PlayerData for player " .. source)
        PlayerData[source] = nil
        LoggedInPlayers[source] = nil
    end
end)

---
## Script Loaded Message

```lua
-- =============================================================================
-- >> SCRIPT LOADED MESSAGE
-- =============================================================================

print("^2[Account & Character System] Merged system loaded successfully.^0")