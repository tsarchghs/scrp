-- MySQL Wrapper for mysql-async 3.3.2 compatibility
-- This provides a unified interface for all database operations

MySQL_Wrapper = {}

-- Execute query (for INSERT, UPDATE, DELETE, CREATE TABLE)
function MySQL_Wrapper.execute(query, parameters, callback)
    if callback then
        MySQL.Async.execute(query, parameters or {}, callback)
    else
        MySQL.Async.execute(query, parameters or {})
    end
end

-- Fetch single row
function MySQL_Wrapper.fetchScalar(query, parameters, callback)
    MySQL.Async.fetchScalar(query, parameters or {}, callback)
end

-- Fetch single row
function MySQL_Wrapper.fetchSingle(query, parameters, callback)
    MySQL.Async.fetchSingle(query, parameters or {}, callback)
end

-- Fetch all rows
function MySQL_Wrapper.fetchAll(query, parameters, callback)
    MySQL.Async.fetchAll(query, parameters or {}, callback)
end

-- Insert and get ID
function MySQL_Wrapper.insert(query, parameters, callback)
    MySQL.Async.insert(query, parameters or {}, callback)
end

-- Transaction support
function MySQL_Wrapper.transaction(queries, parameters, callback)
    MySQL.Async.transaction(queries, parameters or {}, callback)
end

-- Legacy compatibility - replace old MySQL.query calls
function MySQL_Wrapper.query(query, parameters, callback)
    if string.find(string.upper(query), "SELECT") then
        -- It's a SELECT query
        MySQL.Async.fetchAll(query, parameters or {}, function(result)
            if callback then
                callback(result)
            end
        end)
    elseif string.find(string.upper(query), "INSERT") then
        -- It's an INSERT query
        MySQL.Async.insert(query, parameters or {}, function(insertId)
            if callback then
                callback({insertId = insertId, affectedRows = 1})
            end
        end)
    else
        -- It's UPDATE, DELETE, or DDL
        MySQL.Async.execute(query, parameters or {}, function(affectedRows)
            if callback then
                callback({affectedRows = affectedRows})
            end
        end)
    end
end

-- Make it globally available
MySQL.query = MySQL_Wrapper.query

print("[SC:RP] MySQL Wrapper loaded - mysql-async 3.3.2 compatible")
