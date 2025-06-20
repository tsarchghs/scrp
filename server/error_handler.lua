-- Professional Error Handler and Logger
-- Handles all server errors and provides detailed logging

ErrorHandler = {}
ErrorHandler.logs = {}

-- Log levels
ErrorHandler.LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
}

-- Initialize error handling
function ErrorHandler.init()
    -- Create logs table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `server_logs` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `LogLevel` varchar(16) NOT NULL,
            `Source` varchar(64) NOT NULL,
            `Message` text NOT NULL,
            `StackTrace` text DEFAULT NULL,
            `PlayerSource` int(11) DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            INDEX idx_level (`LogLevel`),
            INDEX idx_timestamp (`Timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    print("[SC:RP] Error Handler initialized")
end

-- Log function
function ErrorHandler.log(level, source, message, stackTrace, playerSource)
    local levelName = "INFO"
    for name, value in pairs(ErrorHandler.LOG_LEVELS) do
        if value == level then
            levelName = name
            break
        end
    end
    
    -- Console output with colors
    local color = "^7" -- White
    if level == ErrorHandler.LOG_LEVELS.WARNING then
        color = "^3" -- Yellow
    elseif level == ErrorHandler.LOG_LEVELS.ERROR then
        color = "^1" -- Red
    elseif level == ErrorHandler.LOG_LEVELS.CRITICAL then
        color = "^9" -- Bright Red
    elseif level == ErrorHandler.LOG_LEVELS.DEBUG then
        color = "^5" -- Blue
    end
    
    print(string.format("%s[SC:RP %s] %s: %s^7", color, levelName, source, message))
    
    -- Database logging
    MySQL.Async.execute("INSERT INTO server_logs (LogLevel, Source, Message, StackTrace, PlayerSource) VALUES (@level, @source, @message, @stack, @player)", {
        ['@level'] = levelName,
        ['@source'] = source,
        ['@message'] = message,
        ['@stack'] = stackTrace,
        ['@player'] = playerSource
    })
    
    -- Store in memory for admin commands
    table.insert(ErrorHandler.logs, {
        level = levelName,
        source = source,
        message = message,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        playerSource = playerSource
    })
    
    -- Keep only last 100 logs in memory
    if #ErrorHandler.logs > 100 then
        table.remove(ErrorHandler.logs, 1)
    end
end

-- Wrapper functions for easy use
function ErrorHandler.debug(source, message, playerSource)
    ErrorHandler.log(ErrorHandler.LOG_LEVELS.DEBUG, source, message, nil, playerSource)
end

function ErrorHandler.info(source, message, playerSource)
    ErrorHandler.log(ErrorHandler.LOG_LEVELS.INFO, source, message, nil, playerSource)
end

function ErrorHandler.warning(source, message, playerSource)
    ErrorHandler.log(ErrorHandler.LOG_LEVELS.WARNING, source, message, nil, playerSource)
end

function ErrorHandler.error(source, message, stackTrace, playerSource)
    ErrorHandler.log(ErrorHandler.LOG_LEVELS.ERROR, source, message, stackTrace, playerSource)
end

function ErrorHandler.critical(source, message, stackTrace, playerSource)
    ErrorHandler.log(ErrorHandler.LOG_LEVELS.CRITICAL, source, message, stackTrace, playerSource)
end

-- Safe function execution wrapper
function ErrorHandler.safeCall(func, source, ...)
    local success, result = pcall(func, ...)
    if not success then
        ErrorHandler.error(source or "Unknown", "Function execution failed: " .. tostring(result), debug.traceback())
        return false, result
    end
    return true, result
end

-- Get recent logs for admin commands
function ErrorHandler.getRecentLogs(count)
    count = count or 10
    local logs = {}
    local start = math.max(1, #ErrorHandler.logs - count + 1)
    
    for i = start, #ErrorHandler.logs do
        table.insert(logs, ErrorHandler.logs[i])
    end
    
    return logs
end

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ErrorHandler.init()
    end
end)
