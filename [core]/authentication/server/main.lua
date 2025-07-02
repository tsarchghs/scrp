local Players = {}
local loginAttempts = {}
local bannedIPs = {}

-- Function to check if a player is logged in
function IsPlayerLoggedIn(source)
    return Players[source] and Players[source].isLoggedIn
end

-- Export the function for other resources to use
exports('IsPlayerLoggedIn', IsPlayerLoggedIn)

-- Generate a random salt
function generateSalt()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local salt = ""
    for i = 1, 16 do
        local rand = math.random(1, #chars)
        salt = salt .. string.sub(chars, rand, rand)
    end
    return salt
end

-- Hash the password with the salt
function hashPassword(password, salt)
    -- In a real implementation, use a more secure hashing algorithm like bcrypt
    return string.format("%x", string.crc32(password .. salt))
end

-- Validate password strength
function validatePasswordStrength(password)
    if string.len(password) < Config.Security.PasswordMinLength then
        return false, string.format(Config.Messages.PasswordTooShort, Config.Security.PasswordMinLength)
    end
    if Config.Security.RequireStrongPassword then
        if not (string.match(password, "%u") and string.match(password, "%l") and string.match(password, "%d") and string.match(password, "%W")) then
            return false, Config.Messages.PasswordNotStrong
        end
    end
    return true
end

-- Log security events
function logSecurityEvent(userId, ip, action, details, severity)
    MySQL.Async.execute(
        "INSERT INTO security_logs (user_id, ip, action, details, severity) VALUES (@userId, @ip, @action, @details, @severity)",
        {
            ['@userId'] = userId,
            ['@ip'] = ip,
            ['@action'] = action,
            ['@details'] = details,
            ['@severity'] = severity or 'LOW'
        }
    )
end

-- Register command
RegisterCommand("register", function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    local password = args[1]
    local ip = GetPlayerEndpoint(source)

    if not password then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Usage: /register [password]"}
        })
        return
    end

    local isStrong, message = validatePasswordStrength(password)
    if not isStrong then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", message}
        })
        return
    end

    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM users WHERE name = @name", {['@name'] = playerName}, function(count)
        if count > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", Config.Messages.UsernameExists}
            })
            logSecurityEvent(nil, ip, "REGISTER_FAILED", "Username already exists: " .. playerName, "LOW")
            return
        end

        local salt = generateSalt()
        local hashedPassword = hashPassword(password, salt)
        local license = GetPlayerIdentifier(source, 0)

        MySQL.Async.execute(
            "INSERT INTO users (identifier, license, name, password, salt, last_login) VALUES (@identifier, @license, @name, @password, @salt, NOW())",
            {
                ['@identifier'] = GetPlayerIdentifier(source, 1),
                ['@license'] = license,
                ['@name'] = playerName,
                ['@password'] = hashedPassword,
                ['@salt'] = salt
            },
            function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {0, 255, 0},
                        multiline = true,
                        args = {"System", Config.Messages.RegisterSuccess}
                    })
                    logSecurityEvent(nil, ip, "REGISTER_SUCCESS", "Account created: " .. playerName, "LOW")
                    -- Automatically log in the player after registration
                    loginPlayer(source, playerName, password)
                else
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {"System", Config.Messages.RegisterFailed}
                    })
                    logSecurityEvent(nil, ip, "REGISTER_ERROR", "Database error for username: " .. playerName, "MEDIUM")
                end
            end
        )
    end)
end, false)

-- Login command
RegisterCommand("login", function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    local password = args[1]

    if not password then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Usage: /login [password]"}
        })
        return
    end

    loginPlayer(source, playerName, password)
end, false)

function loginPlayer(source, playerName, password)
    local ip = GetPlayerEndpoint(source)

    if bannedIPs[ip] and os.time() < bannedIPs[ip] then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", Config.Messages.IPBanned}
        })
        return
    end

    local attemptKey = ip .. "_" .. playerName
    if loginAttempts[attemptKey] and loginAttempts[attemptKey].count >= Config.Security.MaxLoginAttempts and os.time() < loginAttempts[attemptKey].lockoutUntil then
        local timeLeft = loginAttempts[attemptKey].lockoutUntil - os.time()
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", string.format(Config.Messages.TooManyAttempts, timeLeft)}
        })
        return
    end

    MySQL.Async.fetchAll("SELECT * FROM users WHERE name = @name", {['@name'] = playerName}, function(result)
        if #result > 0 then
            local user = result[1]
            local hashedPassword = hashPassword(password, user.salt)

            if hashedPassword == user.password then
                Players[source] = {
                    isLoggedIn = true,
                    data = user
                }
                loginAttempts[attemptKey] = nil -- Reset attempts on successful login
                TriggerClientEvent('authentication:loginSuccess', source)
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {"System", string.format(Config.Messages.LoginSuccess, playerName)}
                })
                MySQL.Async.execute("UPDATE users SET last_login = NOW() WHERE id = @id", {['@id'] = user.id})
                logSecurityEvent(user.id, ip, "LOGIN_SUCCESS", "Successful login", "LOW")
            else
                recordFailedLogin(source, playerName, ip, "INVALID_PASSWORD")
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"System", Config.Messages.LoginFailed}
                })
            end
        else
            recordFailedLogin(source, playerName, ip, "INVALID_USERNAME")
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", Config.Messages.LoginFailed}
            })
        end
    end)
end

function recordFailedLogin(source, username, ip, reason)
    local attemptKey = ip .. "_" .. username
    if not loginAttempts[attemptKey] or os.time() >= (loginAttempts[attemptKey].lockoutUntil or 0) then
        loginAttempts[attemptKey] = {count = 0, lockoutUntil = 0}
    end

    loginAttempts[attemptKey].count = loginAttempts[attemptKey].count + 1

    if loginAttempts[attemptKey].count >= Config.Security.MaxLoginAttempts then
        loginAttempts[attemptKey].lockoutUntil = os.time() + Config.Security.LockoutDuration
    end

    if loginAttempts[attemptKey].count >= Config.Security.IPBanAfterFailedAttempts then
        bannedIPs[ip] = os.time() + Config.Security.LockoutDuration * 2 -- Ban for double the lockout time
        logSecurityEvent(nil, ip, "IP_BANNED", "Too many failed login attempts", "HIGH")
    end

    MySQL.Async.fetchScalar('SELECT id FROM users WHERE name = @name', {['@name'] = username}, function(userId)
        MySQL.Async.execute(
            "INSERT INTO login_history (user_id, ip, login_time, success, failure_reason) VALUES (@userId, @ip, NOW(), 0, @reason)",
            {
                ['@userId'] = userId or 0,
                ['@ip'] = ip,
                ['@reason'] = reason
            }
        )
        logSecurityEvent(userId, ip, "LOGIN_FAILED", "Failed login: " .. reason, "MEDIUM")
    end)
end

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local source = source
    local license = GetPlayerIdentifier(source, 0)

    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM users WHERE license = @license", {['@license'] = license}, function(count)
        if count > 0 then
            deferrals.update(string.format("Welcome back, %s. Please log in.", playerName))
        else
            deferrals.update(string.format("Welcome, %s. Please register a new account.", playerName))
        end
        deferrals.done()
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if Players[source] then
        logSecurityEvent(Players[source].data.id, GetPlayerEndpoint(source), "LOGOUT", "Player disconnected", "LOW")
        Players[source] = nil
    end
end)

-- This will prevent any command from being executed if the player is not logged in.
-- This is a simple implementation. A more robust solution would involve a more granular permission system.
AddEventHandler('chatMessage', function(source, author, text)
    if text:sub(1, 1) == '/' then
        local command = text:sub(2):split(' ')[1]
        if command ~= 'login' and command ~= 'register' then
            if not IsPlayerLoggedIn(source) then
                CancelEvent()
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"System", "You must be logged in to use this command."}
                })
                TriggerClientEvent('authentication:showHelp', source)
            end
        end
    end
end)

-- Cleanup expired IP bans and login attempts
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        local currentTime = os.time()
        for ip, expiry in pairs(bannedIPs) do
            if currentTime > expiry then
                bannedIPs[ip] = nil
            end
        end
        for key, data in pairs(loginAttempts) do
            if data.lockoutUntil and currentTime > data.lockoutUntil then
                loginAttempts[key] = nil
            end
        end
    end
end)