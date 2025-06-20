-- Account Management System
-- Professional SA-MP Style Authentication

-- Register new account
function RegisterAccount(source, password)
    if not source or not password then
        SendErrorMessage(source, "Invalid parameters for registration!")
        return false
    end
    
    if string.len(password) < 4 then
        SendErrorMessage(source, "Password must be at least 4 characters long!")
        return false
    end
    
    local playerName = GetPlayerName(source)
    
    -- Check if account already exists
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM accounts WHERE Username = @username', {
        ['@username'] = playerName
    }, function(count)
        if count > 0 then
            SendErrorMessage(source, "An account with this name already exists!")
            SendInfoMessage(source, "Use /login [password] to login to your existing account")
            return
        end
        
        -- Create new account
        MySQL.Async.execute('INSERT INTO accounts (Username, Password, RegisterDate, LastLogin, IP) VALUES (@username, @password, NOW(), NOW(), @ip)', {
            ['@username'] = playerName,
            ['@password'] = password, -- In production, use proper hashing
            ['@ip'] = GetPlayerEndpoint(source)
        }, function(insertId)
            if insertId then
                SendSuccessMessage(source, "Account registered successfully!")
                SendInfoMessage(source, "You can now login with /login " .. password)
                LogAction(source, "ACCOUNT_REGISTER", "New account created with ID: " .. insertId)
                
                -- Auto-login after registration
                LoginAccount(source, password)
            else
                SendErrorMessage(source, "Failed to create account. Please try again.")
            end
        end)
    end)
end

function LoginAccount(source, password)
    if not source or not password then
        SendErrorMessage(source, "Invalid parameters for login!")
        return false
    end

    if PlayerData[source] and PlayerData[source].isLoggedIn then
        SendWarningMessage(source, "You are already logged in!")
        return false
    end

    local playerName = GetPlayerName(source)

    MySQL.Async.fetchAll('SELECT * FROM accounts WHERE Username = @username AND Password = @password', {
        ['@username'] = playerName,
        ['@password'] = password
    }, function(result)
        if #result > 0 then
            local accountData = result[1]

            MySQL.Async.execute('UPDATE accounts SET LastLogin = NOW(), IP = @ip WHERE AccountID = @id', {
                ['@ip'] = GetPlayerEndpoint(source),
                ['@id'] = accountData.AccountID
            })

            if not PlayerData[source] then
                PlayerData[source] = {}
            end

            PlayerData[source].isLoggedIn = true
            PlayerData[source].isRegistered = true
            PlayerData[source].accountData = accountData
            LoggedInPlayers[source] = true

            UnblockPlayerCommands(source)

            SendSuccessMessage(source, "Successfully logged in!")
            SendInfoMessage(source, "Welcome back, " .. playerName .. "!")
            SendInfoMessage(source, "Last login: " .. (accountData.LastLogin or "Never"))

            LogAction(source, "ACCOUNT_LOGIN", "Successfully logged in to account ID: " .. accountData.AccountID)

            LoadPlayerCharacters(source, accountData.AccountID)
        else
            SendErrorMessage(source, "Invalid username or password!")
            SendInfoMessage(source, "If you don't have an account, use /register [password]")
            LogAction(source, "ACCOUNT_LOGIN_FAIL", "Failed login attempt for player: " .. playerName)
        end
    end)
end


-- Load player characters
function LoadPlayerCharacters(source, accountId)
    MySQL.Async.fetchAll('SELECT * FROM characters WHERE AccountID = @accountId', {
        ['@accountId'] = accountId
    }, function(characters)
        if #characters > 0 then
            -- Player has characters, let them select one
            SendInfoMessage(source, "You have " .. #characters .. " character(s):")
            
            for i, char in ipairs(characters) do
                SendFormattedMessage(source, "WHITE", "", string.format("%d. %s (Level %d)", i, char.Name, char.Level))
            end
            
            SendInfoMessage(source, "Use /selectchar [number] to select a character")
            SendInfoMessage(source, "Or use /createchar [name] to create a new character")
            
            -- Store characters for selection
            PlayerData[source].availableCharacters = characters
            
        else
            -- No characters, prompt to create one
            SendInfoMessage(source, "You don't have any characters yet.")
            SendInfoMessage(source, "Use /createchar [name] to create your first character")
        end
    end)
end

-- Select character
function SelectCharacter(source, charIndex)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in first!")
        return
    end
    
    if not PlayerData[source].availableCharacters then
        SendErrorMessage(source, "No characters available!")
        return
    end
    
    local characters = PlayerData[source].availableCharacters
    charIndex = tonumber(charIndex)
    
    if not charIndex or charIndex < 1 or charIndex > #characters then
        SendErrorMessage(source, "Invalid character number!")
        return
    end
    
    local selectedChar = characters[charIndex]
    
    -- Load character data
    loadPlayerData(source, selectedChar.CharacterID)
    
    SendSuccessMessage(source, "Character '" .. selectedChar.Name .. "' selected!")
    LogAction(source, "CHARACTER_SELECT", "Selected character: " .. selectedChar.Name)
end

-- Create new character
function CreateCharacter(source, name, age, gender, skin)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        SendErrorMessage(source, "You must be logged in first!")
        return
    end
    
    if not name or string.len(name) < 3 then
        SendErrorMessage(source, "Character name must be at least 3 characters long!")
        return
    end
    
    -- Set default values
    age = tonumber(age) or 25
    gender = tonumber(gender) or 1
    skin = tonumber(skin) or 1
    
    if age < 18 or age > 80 then
        SendErrorMessage(source, "Age must be between 18 and 80!")
        return
    end
    
    local accountId = PlayerData[source].accountData.AccountID
    
    -- Check if character name exists
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM characters WHERE Name = @name', {
        ['@name'] = name
    }, function(count)
        if count > 0 then
            SendErrorMessage(source, "A character with this name already exists!")
            return
        end
        
        -- Create character
        createCharacter(source, accountId, name, age, gender, skin)
    end)
end

-- Register commands
RegisterCommand('register', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "Usage: /register [password]")
        return
    end
    
    local password = args[1]
    RegisterAccount(source, password)
end, false)

RegisterCommand('login', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "Usage: /login [password]")
        return
    end
    
    local password = args[1]
    LoginAccount(source, password)
end, false)

RegisterCommand('selectchar', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "Usage: /selectchar [number]")
        return
    end
    
    local charIndex = tonumber(args[1])
    SelectCharacter(source, charIndex)
end, false)

RegisterCommand('createchar', function(source, args, rawCommand)
    if #args < 1 then
        SendErrorMessage(source, "Usage: /createchar [name] [age] [gender] [skin]")
        SendInfoMessage(source, "Example: /createchar John_Doe 25 1 1")
        return
    end
    
    local name = args[1]
    local age = args[2]
    local gender = args[3]
    local skin = args[4]
    
    CreateCharacter(source, name, age, gender, skin)
end, false)

print("^2[SC:RP] Account system loaded successfully!^0")
