--[[
    SQL to create the necessary tables:

    CREATE TABLE `fishing_inventory` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `identifier` VARCHAR(50) NOT NULL,
        `item` VARCHAR(50) NOT NULL,
        `count` INT(11) NOT NULL,
        PRIMARY KEY (`id`)
    );

    CREATE TABLE `fishing_sessions` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `leader` VARCHAR(50) NOT NULL,
        `members` TEXT NOT NULL,
        `checkpoint` INT(11) NOT NULL DEFAULT 1,
        `active` BOOLEAN NOT NULL DEFAULT TRUE,
        PRIMARY KEY (`id`)
    );
]]

local fishingSessions = {}

-- Function to get a player's fishing session
function getPlayerSession(playerId)
    for sessionId, session in pairs(fishingSessions) do
        for _, memberId in ipairs(session.members) do
            if memberId == playerId then
                return sessionId, session
            end
        end
    end
    return nil, nil
end

-- Function to check if a player is in a fishing session
function isPlayerFishing(playerId)
    local _, session = getPlayerSession(playerId)
    return session ~= nil
end

-- Command to start the fishing job
RegisterCommand('startfishing', function(source, args, rawCommand)
    local playerId = source
    if not isPlayerFishing(playerId) then
        local sessionId = #fishingSessions + 1
        fishingSessions[sessionId] = {
            leader = playerId,
            members = {playerId},
            checkpoint = 1,
            active = true
        }
        TriggerClientEvent('fishing:startJob', playerId, fishingSessions[sessionId])
        TriggerClientEvent('chat:addMessage', -1, {
            args = {"^2FISHING", "A new fishing session has started! Type /joinfishing to join."}
        })
    else
        TriggerClientEvent('chat:addMessage', playerId, {
            args = {"^1ERROR", "You are already in a fishing session."}
        })
    end
end, false)

-- Command to join a fishing session
RegisterCommand('joinfishing', function(source, args, rawCommand)
    local playerId = source
    if not isPlayerFishing(playerId) then
        local joined = false
        for _, session in pairs(fishingSessions) do
            if session.active and #session.members < 4 then -- Max 4 players per session
                table.insert(session.members, playerId)
                TriggerClientEvent('fishing:startJob', playerId, session)
                TriggerClientEvent('chat:addMessage', -1, {
                    args = {"^2FISHING", GetPlayerName(playerId) .. " has joined a fishing session."}
                })
                joined = true
                break
            end
        end
        if not joined then
            TriggerClientEvent('chat:addMessage', playerId, {
                args = {"^1ERROR", "No available fishing sessions to join."}
            })
        end
    else
        TriggerClientEvent('chat:addMessage', playerId, {
            args = {"^1ERROR", "You are already in a fishing session."}
        })
    end
end, false)

-- Command to fish at a checkpoint
RegisterCommand('fish', function(source, args, rawCommand)
    local playerId = source
    if isPlayerFishing(playerId) then
        TriggerClientEvent('fishing:fish', playerId)
    else
        TriggerClientEvent('chat:addMessage', playerId, {
            args = {"^1ERROR", "You are not in a fishing session."}
        })
    end
end, false)

-- Command to leave a fishing session
RegisterCommand('leavefishing', function(source, args, rawCommand)
    local playerId = source
    local sessionId, session = getPlayerSession(playerId)
    if session then
        for i, memberId in ipairs(session.members) do
            if memberId == playerId then
                table.remove(session.members, i)
                TriggerClientEvent('fishing:endJob', playerId)
                TriggerClientEvent('chat:addMessage', playerId, {
                    args = {"^2FISHING", "You have left the fishing session."}
                })
                break
            end
        end

        if #session.members == 0 then
            fishingSessions[sessionId] = nil
        elseif session.leader == playerId then
            session.leader = session.members[1]
            TriggerClientEvent('chat:addMessage', -1, {
                args = {"^2FISHING", GetPlayerName(session.leader) .. " is the new leader of the fishing session."}
            })
        end
    else
        TriggerClientEvent('chat:addMessage', playerId, {
            args = {"^1ERROR", "You are not in a fishing session."}
        })
    end
end, false)

-- Event to handle giving fish to the player
RegisterNetEvent('fishing:giveFish')
AddEventHandler('fishing:giveFish', function()
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    local fish = Config.FishTypes[math.random(1, #Config.FishTypes)]

    MySQL.Async.execute('INSERT INTO fishing_inventory (identifier, item, count) VALUES (@identifier, @item, 1) ON DUPLICATE KEY UPDATE count = count + 1', {
        ['@identifier'] = identifier,
        ['@item'] = fish.name
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('chat:addMessage', playerId, {
                args = {"^2FISHING", "You caught a " .. fish.name .. "!"}
            })
        end
    end)
end)

-- Command to sell fish
RegisterCommand('sellfish', function(source, args, rawCommand)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]

    MySQL.Async.fetchAll('SELECT * FROM fishing_inventory WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result and #result > 0 then
            local totalValue = 0
            for _, item in ipairs(result) do
                for _, fishType in ipairs(Config.FishTypes) do
                    if item.item == fishType.name then
                        totalValue = totalValue + (fishType.price * item.count)
                    end
                end
            end

            if totalValue > 0 then
                -- This is where you would integrate with your economy script to give money
                -- For now, we'll just show a message
                TriggerClientEvent('chat:addMessage', playerId, {
                    args = {"^2FISHING", "You sold your fish for $" .. totalValue .. "."}
                })

                MySQL.Async.execute('DELETE FROM fishing_inventory WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                })
            else
                TriggerClientEvent('chat:addMessage', playerId, {
                    args = {"^1ERROR", "You have no fish to sell."}
                })
            end
        else
            TriggerClientEvent('chat:addMessage', playerId, {
                args = {"^1ERROR", "You have no fish to sell."}
            })
        end
    end)
end, false)

-- Event to handle checkpoint progression
RegisterNetEvent('fishing:checkpointReached')
AddEventHandler('fishing:checkpointReached', function(sessionId)
    if fishingSessions[sessionId] then
        fishingSessions[sessionId].checkpoint = fishingSessions[sessionId].checkpoint + 1
        if fishingSessions[sessionId].checkpoint > #Config.Checkpoints then
            -- End of job
            for _, memberId in ipairs(fishingSessions[sessionId].members) do
                TriggerClientEvent('fishing:endJob', memberId)
                TriggerClientEvent('chat:addMessage', memberId, {
                    args = {"^2FISHING", "You have completed the fishing job!"}
                })
            end
            fishingSessions[sessionId] = nil
        else
            -- Next checkpoint
            for _, memberId in ipairs(fishingSessions[sessionId].members) do
                TriggerClientEvent('fishing:updateCheckpoint', memberId, fishingSessions[sessionId])
            end
        end
    end
end)

-- Event to handle player disconnections
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local sessionId, session = getPlayerSession(playerId)
    if session then
        for i, memberId in ipairs(session.members) do
            if memberId == playerId then
                table.remove(session.members, i)
                break
            end
        end

        if #session.members == 0 then
            fishingSessions[sessionId] = nil
        elseif session.leader == playerId then
            session.leader = session.members[1]
            TriggerClientEvent('chat:addMessage', -1, {
                args = {"^2FISHING", GetPlayerName(session.leader) .. " is the new leader of the fishing session."}
            })
        end
    end
end)