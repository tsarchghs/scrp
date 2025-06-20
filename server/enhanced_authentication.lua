-- Enhanced Authentication System with Better Security
-- Compatible with mysql-async 3.3.2 and FiveM artifact 16085

EnhancedAuth = {
    loginAttempts = {},
    sessionTokens = {},
    bannedIPs = {},
    securityConfig = {
        maxLoginAttempts = 5,
        lockoutDuration = 300, -- 5 minutes
        sessionTimeout = 3600, -- 1 hour
        passwordMinLength = 6,
        requireStrongPassword = true,
        enableTwoFactor = false
    }
}

-- Initialize enhanced authentication tables
function initializeEnhancedAuthTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `enhanced_accounts` (
            `AccountID` int(11) NOT NULL AUTO_INCREMENT,
            `Username` varchar(24) NOT NULL UNIQUE,
            `Email` varchar(100) DEFAULT NULL,
            `PasswordHash` varchar(255) NOT NULL,
            `Salt` varchar(32) NOT NULL,
            `RegisterDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `LastLogin` datetime DEFAULT NULL,
            `LastIP` varchar(45) DEFAULT NULL,
            `LoginAttempts` int(11) DEFAULT 0,
            `LockedUntil` datetime DEFAULT NULL,
            `AdminLevel` int(2) DEFAULT 0,
            `IsBanned` tinyint(1) DEFAULT 0,
            `BanReason` text DEFAULT NULL,
            `TwoFactorSecret` varchar(32) DEFAULT NULL,
            `TwoFactorEnabled` tinyint(1) DEFAULT 0,
            `SessionToken` varchar(64) DEFAULT NULL,
            `SessionExpiry` datetime DEFAULT NULL,
            `SecurityQuestions` text DEFAULT NULL,
            `AccountFlags` int(11) DEFAULT 0,
            PRIMARY KEY (`AccountID`),
            INDEX `idx_username` (`Username`),
            INDEX `idx_email` (`Email`),
            INDEX `idx_session` (`SessionToken`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `login_history` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `IP` varchar(45) NOT NULL,
            `UserAgent` varchar(255) DEFAULT NULL,
            `LoginTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `Success` tinyint(1) NOT NULL,
            `FailureReason` varchar(100) DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`AccountID`) REFERENCES `enhanced_accounts`(`AccountID`) ON DELETE CASCADE,
            INDEX `idx_account_time` (`AccountID`, `LoginTime`),
            INDEX `idx_ip_time` (`IP`, `LoginTime`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `security_logs` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) DEFAULT NULL,
            `IP` varchar(45) NOT NULL,
            `Action` varchar(50) NOT NULL,
            `Details` text DEFAULT NULL,
            `Severity` enum('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            INDEX `idx_account` (`AccountID`),
            INDEX `idx_action` (`Action`),
            INDEX `idx_severity` (`Severity`),
            INDEX `idx_timestamp` (`Timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("[SC:RP] Enhanced authentication tables initialized.")
end

-- Generate secure password hash
function generatePasswordHash(password, salt)
    -- In a real implementation, use bcrypt or similar
    -- This is a simplified version for demonstration
    return string.format("%x", string.crc32(password .. salt))
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

-- Generate session token
function generateSessionToken()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local token = ""
    for i = 1, 32 do
        local rand = math.random(1, #chars)
        token = token .. string.sub(chars, rand, rand)
    end
    return token
end

-- Validate password strength
function validatePasswordStrength(password)
    if #password < EnhancedAuth.securityConfig.passwordMinLength then
        return false, "Password must be at least " .. EnhancedAuth.securityConfig.passwordMinLength .. " characters long"
    end
    
    if EnhancedAuth.securityConfig.requireStrongPassword then
        local hasUpper = string.match(password, "%u")
        local hasLower = string.match(password, "%l")
        local hasDigit = string.match(password, "%d")
        local hasSpecial = string.match(password, "[%W]")
        
        if not (hasUpper and hasLower and hasDigit and hasSpecial) then
            return false, "Password must contain uppercase, lowercase, number, and special character"
        end
    end
    
    return true, "Password is strong"
end

-- Check if IP is banned
function isIPBanned(ip)
    return EnhancedAuth.bannedIPs[ip] and EnhancedAuth.bannedIPs[ip] > os.time()
end

-- Log security event
function logSecurityEvent(accountId, ip, action, details, severity)
    MySQL.Async.execute("INSERT INTO security_logs (AccountID, IP, Action, Details, Severity) VALUES (@accountId, @ip, @action, @details, @severity)", {
        ['@accountId'] = accountId,
        ['@ip'] = ip,
        ['@action'] = action,
        ['@details'] = details,
        ['@severity'] = severity or 'LOW'
    })
end

-- Enhanced registration
function enhancedRegisterAccount(source, username, password, email)
    local ip = GetPlayerEndpoint(source)
    
    -- Check if IP is banned
    if isIPBanned(ip) then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Your IP is temporarily banned.")
        return false
    end
    
    -- Validate input
    if not username or not password then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Username and password are required.")
        return false
    end
    
    if #username < 3 or #username > 24 then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Username must be 3-24 characters long.")
        return false
    end
    
    -- Validate password strength
    local isStrong, message = validatePasswordStrength(password)
    if not isStrong then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, message)
        return false
    end
    
    -- Check if username exists
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM enhanced_accounts WHERE Username = @username', {
        ['@username'] = username
    }, function(count)
        if count > 0 then
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Username already exists.")
            logSecurityEvent(nil, ip, "REGISTER_FAILED", "Username already exists: " .. username, "LOW")
            return
        end
        
        -- Create account
        local salt = generateSalt()
        local passwordHash = generatePasswordHash(password, salt)
        
        MySQL.Async.execute('INSERT INTO enhanced_accounts (Username, Email, PasswordHash, Salt, LastIP) VALUES (@username, @email, @passwordHash, @salt, @ip)', {
            ['@username'] = username,
            ['@email'] = email,
            ['@passwordHash'] = passwordHash,
            ['@salt'] = salt,
            ['@ip'] = ip
        }, function(insertId)
            if insertId then
                TriggerClientEvent('chatMessage', source, "[AUTH]", {0, 255, 0}, "Account registered successfully! You can now login.")
                logSecurityEvent(insertId, ip, "REGISTER_SUCCESS", "Account created: " .. username, "LOW")
                
                -- Auto-login after registration
                enhancedLoginAccount(source, username, password)
            else
                TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Failed to create account. Please try again.")
                logSecurityEvent(nil, ip, "REGISTER_ERROR", "Database error for username: " .. username, "MEDIUM")
            end
        end)
    end)
end

-- Enhanced login
function enhancedLoginAccount(source, username, password)
    local ip = GetPlayerEndpoint(source)
    
    -- Check if IP is banned
    if isIPBanned(ip) then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Your IP is temporarily banned.")
        return false
    end
    
    -- Check login attempts
    local attemptKey = ip .. "_" .. username
    if EnhancedAuth.loginAttempts[attemptKey] then
        if EnhancedAuth.loginAttempts[attemptKey].count >= EnhancedAuth.securityConfig.maxLoginAttempts then
            if os.time() < EnhancedAuth.loginAttempts[attemptKey].lockoutUntil then
                local timeLeft = EnhancedAuth.loginAttempts[attemptKey].lockoutUntil - os.time()
                TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, 
                    "Too many failed attempts. Try again in " .. timeLeft .. " seconds.")
                return false
            else
                -- Reset attempts after lockout period
                EnhancedAuth.loginAttempts[attemptKey] = nil
            end
        end
    end
    
    -- Validate input
    if not username or not password then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Username and password are required.")
        return false
    end
    
    -- Check if player is already logged in
    if PlayerData[source] and PlayerData[source].isLoggedIn then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 165, 0}, "You are already logged in.")
        return false
    end
    
    -- Fetch account data
    MySQL.Async.fetchAll('SELECT * FROM enhanced_accounts WHERE Username = @username', {
        ['@username'] = username
    }, function(result)
        if #result == 0 then
            -- Account doesn't exist
            recordFailedLogin(source, username, ip, "INVALID_USERNAME")
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Invalid username or password.")
            return
        end
        
        local accountData = result[1]
        
        -- Check if account is banned
        if accountData.IsBanned == 1 then
            recordFailedLogin(source, username, ip, "ACCOUNT_BANNED")
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, 
                "Account is banned. Reason: " .. (accountData.BanReason or "No reason provided"))
            return
        end
        
        -- Check if account is locked
        if accountData.LockedUntil and os.time() < os.time(accountData.LockedUntil) then
            recordFailedLogin(source, username, ip, "ACCOUNT_LOCKED")
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Account is temporarily locked.")
            return
        end
        
        -- Verify password
        local passwordHash = generatePasswordHash(password, accountData.Salt)
        if passwordHash ~= accountData.PasswordHash then
            recordFailedLogin(source, username, ip, "INVALID_PASSWORD")
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Invalid username or password.")
            return
        end
        
        -- Generate session token
        local sessionToken = generateSessionToken()
        local sessionExpiry = os.date("%Y-%m-%d %H:%M:%S", os.time() + EnhancedAuth.securityConfig.sessionTimeout)
        
        -- Update account
        MySQL.Async.execute('UPDATE enhanced_accounts SET LastLogin = NOW(), LastIP = @ip, LoginAttempts = 0, LockedUntil = NULL, SessionToken = @token, SessionExpiry = @expiry WHERE AccountID = @id', {
            ['@ip'] = ip,
            ['@token'] = sessionToken,
            ['@expiry'] = sessionExpiry,
            ['@id'] = accountData.AccountID
        })
        
        -- Initialize player data
        if not PlayerData[source] then
            PlayerData[source] = {}
        end
        
        PlayerData[source].isLoggedIn = true
        PlayerData[source].isRegistered = true
        PlayerData[source].accountData = accountData
        PlayerData[source].sessionToken = sessionToken
        LoggedInPlayers[source] = true
        
        -- Store session
        EnhancedAuth.sessionTokens[sessionToken] = {
            source = source,
            accountId = accountData.AccountID,
            expiry = os.time() + EnhancedAuth.securityConfig.sessionTimeout
        }
        
        -- Clear failed attempts
        EnhancedAuth.loginAttempts[attemptKey] = nil
        
        -- Log successful login
        MySQL.Async.execute("INSERT INTO login_history (AccountID, IP, LoginTime, Success) VALUES (@accountId, @ip, NOW(), 1)", {
            ['@accountId'] = accountData.AccountID,
            ['@ip'] = ip
        })
        
        logSecurityEvent(accountData.AccountID, ip, "LOGIN_SUCCESS", "Successful login", "LOW")
        
        TriggerClientEvent('chatMessage', source, "[AUTH]", {0, 255, 0}, "Successfully logged in! Welcome back, " .. username)
        TriggerClientEvent('chatMessage', source, "[AUTH]", {0, 255, 255}, "Last login: " .. (accountData.LastLogin or "Never"))
        
        -- Load player characters
        loadPlayerCharacters(source, accountData.AccountID)
        
        -- Send enhanced UI data
        TriggerClientEvent('scrp:updateAuthStatus', source, {
            isLoggedIn = true,
            username = username,
            accountLevel = accountData.AdminLevel,
            sessionExpiry = sessionExpiry
        })
    end)
end

-- Record failed login attempt
function recordFailedLogin(source, username, ip, reason)
    local attemptKey = ip .. "_" .. username
    
    -- Initialize or increment attempts
    if not EnhancedAuth.loginAttempts[attemptKey] then
        EnhancedAuth.loginAttempts[attemptKey] = {count = 0, lockoutUntil = 0}
    end
    
    EnhancedAuth.loginAttempts[attemptKey].count = EnhancedAuth.loginAttempts[attemptKey].count + 1
    
    -- Check if max attempts reached
    if EnhancedAuth.loginAttempts[attemptKey].count >= EnhancedAuth.securityConfig.maxLoginAttempts then
        EnhancedAuth.loginAttempts[attemptKey].lockoutUntil = os.time() + EnhancedAuth.securityConfig.lockoutDuration
        
        -- Temporarily ban IP for repeated failures
        if EnhancedAuth.loginAttempts[attemptKey].count >= EnhancedAuth.securityConfig.maxLoginAttempts * 2 then
            EnhancedAuth.bannedIPs[ip] = os.time() + 3600 -- 1 hour ban
            logSecurityEvent(nil, ip, "IP_BANNED", "Too many failed login attempts", "HIGH")
        end
    end
    
    -- Log failed attempt
    MySQL.Async.fetchScalar('SELECT AccountID FROM enhanced_accounts WHERE Username = @username', {
        ['@username'] = username
    }, function(accountId)
        MySQL.Async.execute("INSERT INTO login_history (AccountID, IP, LoginTime, Success, FailureReason) VALUES (@accountId, @ip, NOW(), 0, @reason)", {
            ['@accountId'] = accountId or 0,
            ['@ip'] = ip,
            ['@reason'] = reason
        })
        
        logSecurityEvent(accountId, ip, "LOGIN_FAILED", "Failed login: " .. reason, "MEDIUM")
    end)
end

-- Validate session token
function validateSession(source, token)
    if not token or not EnhancedAuth.sessionTokens[token] then
        return false
    end
    
    local session = EnhancedAuth.sessionTokens[token]
    if os.time() > session.expiry or session.source ~= source then
        EnhancedAuth.sessionTokens[token] = nil
        return false
    end
    
    return true
end

-- Logout player
function logoutPlayer(source)
    if PlayerData[source] and PlayerData[source].sessionToken then
        EnhancedAuth.sessionTokens[PlayerData[source].sessionToken] = nil
    end
    
    if PlayerData[source] and PlayerData[source].accountData then
        logSecurityEvent(PlayerData[source].accountData.AccountID, GetPlayerEndpoint(source), "LOGOUT", "Player logout", "LOW")
    end
    
    PlayerData[source] = nil
    LoggedInPlayers[source] = nil
    
    TriggerClientEvent('scrp:updateAuthStatus', source, {
        isLoggedIn = false
    })
end

-- Session cleanup thread
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.time()
        for token, session in pairs(EnhancedAuth.sessionTokens) do
            if currentTime > session.expiry then
                -- Session expired
                if PlayerData[session.source] then
                    TriggerClientEvent('chatMessage', session.source, "[AUTH]", {255, 165, 0}, "Session expired. Please login again.")
                    logoutPlayer(session.source)
                end
                EnhancedAuth.sessionTokens[token] = nil
            end
        end
    end
end)

-- Enhanced commands
RegisterCommand('register', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 255, 0}, "Usage: /register [username] [password] [email]")
        return
    end
    
    local username = args[1]
    local password = args[2]
    local email = args[3]
    
    enhancedRegisterAccount(source, username, password, email)
end, false)

RegisterCommand('login', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 255, 0}, "Usage: /login [username] [password]")
        return
    end
    
    local username = args[1]
    local password = args[2]
    
    enhancedLoginAccount(source, username, password)
end, false)

RegisterCommand('logout', function(source, args, rawCommand)
    logoutPlayer(source)
    TriggerClientEvent('chatMessage', source, "[AUTH]", {0, 255, 0}, "Successfully logged out.")
end, false)

-- Initialize enhanced authentication
function initializeEnhancedAuth()
    initializeEnhancedAuthTables()
    print("[SC:RP] Enhanced authentication system initialized.")
end

-- Event handlers
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeEnhancedAuth()
    end
end)

AddEventHandler('playerDropped', function()
    logoutPlayer(source)
end)
