-- Enhanced Commands for the Improved Job System

-- Job-related commands
RegisterCommand('startjob', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 255, 0}, "Usage: /startjob [job_id] [activity_name]")
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 255, 255}, "Available jobs: 1=Delivery, 2=Mechanic, 3=Police, 4=Paramedic, 5=Business")
        return
    end
    
    local jobId = tonumber(args[1])
    local activityName = table.concat(args, " ", 2)
    
    if not jobId then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid job ID.")
        return
    end
    
    startJobActivity(source, jobId, activityName)
end, false)

RegisterCommand('jobinfo', function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 255, 0}, "Usage: /jobinfo [job_id]")
        return
    end
    
    local jobId = tonumber(args[1])
    if not jobId or not EnhancedJobs.jobs[jobId] then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid job ID.")
        return
    end
    
    local job = EnhancedJobs.jobs[jobId]
    local playerJobData = EnhancedJobs.playerJobData[source] and EnhancedJobs.playerJobData[source][jobId]
    
    TriggerClientEvent('chatMessage', source, "[JOB INFO]", {0, 255, 255}, "=== " .. job.name .. " ===")
    TriggerClientEvent('chatMessage', source, "[JOB INFO]", {255, 255, 255}, job.description)
    TriggerClientEvent('chatMessage', source, "[JOB INFO]", {255, 255, 255}, "Base Payment: $" .. job.basePayment)
    TriggerClientEvent('chatMessage', source, "[JOB INFO]", {255, 255, 255}, "Max Level: " .. job.maxLevel)
    TriggerClientEvent('chatMessage', source, "[JOB INFO]", {255, 255, 255}, "Unlock Level: " .. job.unlockLevel)
    
    if playerJobData then
        TriggerClientEvent('chatMessage', source, "[YOUR PROGRESS]", {255, 215, 0}, "Level: " .. playerJobData.level)
        TriggerClientEvent('chatMessage', source, "[YOUR PROGRESS]", {255, 215, 0}, "Experience: " .. playerJobData.experience)
        TriggerClientEvent('chatMessage', source, "[YOUR PROGRESS]", {255, 215, 0}, "Total Earnings: $" .. playerJobData.totalEarnings)
        TriggerClientEvent('chatMessage', source, "[YOUR PROGRESS]", {255, 215, 0}, "Completed Tasks: " .. playerJobData.completedTasks)
        TriggerClientEvent('chatMessage', source, "[YOUR PROGRESS]", {255, 215, 0}, "Reputation: " .. playerJobData.reputation)
    end
    
    TriggerClientEvent('chatMessage', source, "[ACTIVITIES]", {0, 255, 0}, "Available Activities:")
    for _, activity in ipairs(job.activities) do
        local levelReq = activity.minLevel and (" (Level " .. activity.minLevel .. "+)") or ""
        TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, 
            "• " .. activity.name .. " - $" .. activity.payment .. " - " .. activity.experience .. " XP" .. levelReq)
    end
end, false)

RegisterCommand('myjobs', function(source, args, rawCommand)
    if not EnhancedJobs.playerJobData[source] then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Job data not loaded.")
        return
    end
    
    TriggerClientEvent('chatMessage', source, "[MY JOBS]", {0, 255, 255}, "=== Your Job Progress ===")
    
    for jobId, jobData in pairs(EnhancedJobs.playerJobData[source]) do
        if jobData.level > 0 then
            local job = EnhancedJobs.jobs[jobId]
            if job then
                TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, 
                    string.format("%s: Level %d | $%d earned | %d tasks | %d reputation", 
                    job.name, jobData.level, jobData.totalEarnings, jobData.completedTasks, jobData.reputation))
            end
        end
    end
end, false)

RegisterCommand('jobleaderboard', function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 255, 0}, "Usage: /jobleaderboard [job_id]")
        return
    end
    
    local jobId = tonumber(args[1])
    if not jobId or not EnhancedJobs.jobs[jobId] then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid job ID.")
        return
    end
    
    MySQL.Async.fetchAll("SELECT * FROM job_leaderboards WHERE JobID = @jobId ORDER BY Level DESC, TotalEarnings DESC LIMIT 10", {
        ['@jobId'] = jobId
    }, function(results)
        if results and #results > 0 then
            local job = EnhancedJobs.jobs[jobId]
            TriggerClientEvent('chatMessage', source, "[LEADERBOARD]", {255, 215, 0}, "=== " .. job.name .. " Leaderboard ===")
            
            for i, player in ipairs(results) do
                TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, 
                    string.format("%d. %s - Level %d - $%d - %d tasks", 
                    i, player.CharacterName, player.Level, player.TotalEarnings, player.CompletedTasks))
            end
        else
            TriggerClientEvent('chatMessage', source, "[LEADERBOARD]", {255, 0, 0}, "No leaderboard data available.")
        end
    end)
end, false)

-- Enhanced authentication commands
RegisterCommand('changepassword', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 255, 0}, "Usage: /changepassword [old_password] [new_password]")
        return
    end
    
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "You must be logged in to change your password.")
        return
    end
    
    local oldPassword = args[1]
    local newPassword = args[2]
    
    -- Validate new password strength
    local isStrong, message = validatePasswordStrength(newPassword)
    if not isStrong then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, message)
        return
    end
    
    local accountData = PlayerData[source].accountData
    
    -- Verify old password
    local oldPasswordHash = generatePasswordHash(oldPassword, accountData.Salt)
    if oldPasswordHash ~= accountData.PasswordHash then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Current password is incorrect.")
        return
    end
    
    -- Generate new hash
    local newSalt = generateSalt()
    local newPasswordHash = generatePasswordHash(newPassword, newSalt)
    
    -- Update password
    MySQL.Async.execute('UPDATE enhanced_accounts SET PasswordHash = @hash, Salt = @salt WHERE AccountID = @id', {
        ['@hash'] = newPasswordHash,
        ['@salt'] = newSalt,
        ['@id'] = accountData.AccountID
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('chatMessage', source, "[AUTH]", {0, 255, 0}, "Password changed successfully.")
            logSecurityEvent(accountData.AccountID, GetPlayerEndpoint(source), "PASSWORD_CHANGE", "Password changed", "MEDIUM")
        else
            TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "Failed to change password.")
        end
    end)
end, false)

RegisterCommand('accountinfo', function(source, args, rawCommand)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        TriggerClientEvent('chatMessage', source, "[AUTH]", {255, 0, 0}, "You must be logged in to view account info.")
        return
    end
    
    local accountData = PlayerData[source].accountData
    
    TriggerClientEvent('chatMessage', source, "[ACCOUNT INFO]", {0, 255, 255}, "=== Account Information ===")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Username: " .. accountData.Username)
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Email: " .. (accountData.Email or "Not set"))
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Register Date: " .. accountData.RegisterDate)
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Last Login: " .. (accountData.LastLogin or "Never"))
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Admin Level: " .. accountData.AdminLevel)
    
    -- Show recent login history
    MySQL.Async.fetchAll("SELECT * FROM login_history WHERE AccountID = @accountId ORDER BY LoginTime DESC LIMIT 5", {
        ['@accountId'] = accountData.AccountID
    }, function(history)
        if history and #history > 0 then
            TriggerClientEvent('chatMessage', source, "[LOGIN HISTORY]", {255, 215, 0}, "Recent Login History:")
            for _, login in ipairs(history) do
                local status = login.Success == 1 and "SUCCESS" or ("FAILED: " .. (login.FailureReason or "Unknown"))
                TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, 
                    login.LoginTime .. " - " .. login.IP .. " - " .. status)
            end
        end
    end)
end, false)

-- Admin commands for job management
RegisterCommand('setjoblevel', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 3) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", {255, 0, 0}, "You don't have permission to use this command!")
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 255, 0}, "Usage: /setjoblevel [player_id] [job_id] [level]")
        return
    end
    
    local targetId = tonumber(args[1])
    local jobId = tonumber(args[2])
    local level = tonumber(args[3])
    
    if not targetId or not jobId or not level then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "Invalid parameters.")
        return
    end
    
    if not PlayerData[targetId] or not EnhancedJobs.jobs[jobId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "Invalid player or job ID.")
        return
    end
    
    local job = EnhancedJobs.jobs[jobId]
    if level > job.maxLevel then
        level = job.maxLevel
    end
    
    if not EnhancedJobs.playerJobData[targetId] then
        EnhancedJobs.playerJobData[targetId] = {}
    end
    
    if not EnhancedJobs.playerJobData[targetId][jobId] then
        EnhancedJobs.playerJobData[targetId][jobId] = {
            level = 0, experience = 0, totalEarnings = 0, 
            completedTasks = 0, reputation = 0, unlockedRewards = {}, achievements = {}
        }
    end
    
    EnhancedJobs.playerJobData[targetId][jobId].level = level
    savePlayerJobData(targetId, jobId)
    
    TriggerClientEvent('chatMessage', source, "[ADMIN]", {0, 255, 0}, 
        string.format("Set %s's %s level to %d", PlayerData[targetId].Name, job.name, level))
    TriggerClientEvent('chatMessage', targetId, "[ADMIN]", {255, 215, 0}, 
        string.format("Your %s level has been set to %d", job.name, level))
end, false)

RegisterCommand('givejobxp', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 2) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", {255, 0, 0}, "You don't have permission to use this command!")
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 255, 0}, "Usage: /givejobxp [player_id] [job_id] [experience]")
        return
    end
    
    local targetId = tonumber(args[1])
    local jobId = tonumber(args[2])
    local experience = tonumber(args[3])
    
    if not targetId or not jobId or not experience then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "Invalid parameters.")
        return
    end
    
    if not PlayerData[targetId] or not EnhancedJobs.jobs[jobId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "Invalid player or job ID.")
        return
    end
    
    if not EnhancedJobs.playerJobData[targetId] or not EnhancedJobs.playerJobData[targetId][jobId] then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "Player hasn't started this job yet.")
        return
    end
    
    local job = EnhancedJobs.jobs[jobId]
    local playerJobData = EnhancedJobs.playerJobData[targetId][jobId]
    
    playerJobData.experience = playerJobData.experience + experience
    
    -- Check for level up
    local experienceNeeded = playerJobData.level * 1000 * job.experienceMultiplier
    while playerJobData.experience >= experienceNeeded and playerJobData.level < job.maxLevel do
        playerJobData.level = playerJobData.level + 1
        playerJobData.experience = playerJobData.experience - experienceNeeded
        experienceNeeded = playerJobData.level * 1000 * job.experienceMultiplier
        
        TriggerClientEvent('chatMessage', targetId, "[JOBS]", {255, 215, 0}, 
            "LEVEL UP! " .. job.name .. " Level " .. playerJobData.level)
        
        checkJobRewards(targetId, jobId, playerJobData.level)
    end
    
    savePlayerJobData(targetId, jobId)
    
    TriggerClientEvent('chatMessage', source, "[ADMIN]", {0, 255, 0}, 
        string.format("Gave %d XP to %s for %s", experience, PlayerData[targetId].Name, job.name))
    TriggerClientEvent('chatMessage', targetId, "[ADMIN]", {255, 215, 0}, 
        string.format("You received %d XP for %s", experience, job.name))
end, false)

-- Player status and progression commands
RegisterCommand('mystatus', function(source, args, rawCommand)
    if not PlayerData[source] or not PlayerData[source].isLoggedIn then
        TriggerClientEvent('chatMessage', source, "[STATUS]", {255, 0, 0}, "You must be logged in to view your status.")
        return
    end
    
    local player = PlayerData[source]
    
    TriggerClientEvent('chatMessage', source, "[PLAYER STATUS]", {0, 255, 255}, "=== Your Status ===")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Name: " .. player.Name)
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Level: " .. (player.Level or 1))
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Money: $" .. (player.Money or 0))
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Bank: $" .. (player.BankMoney or 0))
    
    -- Show job summary
    if EnhancedJobs.playerJobData[source] then
        local totalJobLevels = 0
        local totalEarnings = 0
        local activeJobs = 0
        
        for jobId, jobData in pairs(EnhancedJobs.playerJobData[source]) do
            if jobData.level > 0 then
                totalJobLevels = totalJobLevels + jobData.level
                totalEarnings = totalEarnings + jobData.totalEarnings
                activeJobs = activeJobs + 1
            end
        end
        
        TriggerClientEvent('chatMessage', source, "[JOB SUMMARY]", {255, 215, 0}, "=== Job Summary ===")
        TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Active Jobs: " .. activeJobs)
        TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Total Job Levels: " .. totalJobLevels)
        TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "Total Job Earnings: $" .. totalEarnings)
    end
end, false)

RegisterCommand('topplayers', function(source, args, rawCommand)
    -- Show top players across all metrics
    MySQL.Async.fetchAll([[
        SELECT c.Name, c.Level, c.Money + c.BankMoney as TotalMoney,
               COALESCE(SUM(ej.TotalEarnings), 0) as JobEarnings,
               COALESCE(SUM(ej.Level), 0) as TotalJobLevels
        FROM characters c
        LEFT JOIN enhanced_jobs ej ON c.CharacterID = ej.CharacterID
        GROUP BY c.CharacterID, c.Name, c.Level, c.Money, c.BankMoney
        ORDER BY (c.Level + COALESCE(SUM(ej.Level), 0)) DESC
        LIMIT 10
    ]], {}, function(results)
        if results and #results > 0 then
            TriggerClientEvent('chatMessage', source, "[TOP PLAYERS]", {255, 215, 0}, "=== Top Players ===")
            
            for i, player in ipairs(results) do
                TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, 
                    string.format("%d. %s - Level %d - $%d total - %d job levels", 
                    i, player.Name, player.Level, player.TotalMoney, player.TotalJobLevels))
            end
        else
            TriggerClientEvent('chatMessage', source, "[TOP PLAYERS]", {255, 0, 0}, "No player data available.")
        end
    end)
end, false)

-- Utility commands for the enhanced system
RegisterCommand('jobhelp', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[JOB HELP]", {0, 255, 255}, "=== Enhanced Job System Help ===")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/startjob [job_id] [activity] - Start a job activity")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/jobinfo [job_id] - View detailed job information")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/myjobs - View your job progress")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/jobleaderboard [job_id] - View job leaderboard")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/mystatus - View your overall status")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "/topplayers - View top players")
    TriggerClientEvent('chatMessage', source, "", {255, 255, 255}, "")
    TriggerClientEvent('chatMessage', source, "", {255, 215, 0}, "Available Jobs:")
    TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, "1. Delivery Driver - Package delivery across the city")
    TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, "2. Mechanic - Vehicle repair and customization")
    TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, "3. Police Officer - Law enforcement and protection")
    TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, "4. Paramedic - Medical emergency response")
    TriggerClientEvent('chatMessage', source, "", {200, 200, 200}, "5. Business Owner - Manage business operations")
end, false)

print("[SC:RP] Enhanced commands loaded successfully!")
