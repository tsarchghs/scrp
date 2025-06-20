-- Enhanced Job System with Progression and Rewards
-- Compatible with mysql-async 3.3.2 and FiveM artifact 16085

EnhancedJobs = {
    jobs = {
        [1] = {
            name = "Delivery Driver",
            description = "Deliver packages across the city",
            basePayment = 150,
            experienceMultiplier = 1.0,
            maxLevel = 50,
            unlockLevel = 1,
            requirements = {},
            rewards = {
                [5] = {type = "vehicle", model = "burrito", message = "Unlocked company van!"},
                [10] = {type = "money", amount = 5000, message = "Performance bonus: $5,000!"},
                [15] = {type = "skill", skill = "driving", amount = 100, message = "Driving skill boost!"},
                [25] = {type = "access", feature = "premium_routes", message = "Premium delivery routes unlocked!"},
                [50] = {type = "title", title = "Delivery Master", message = "You are now a Delivery Master!"}
            },
            activities = {
                {name = "Package Delivery", payment = 200, experience = 25, cooldown = 300},
                {name = "Express Delivery", payment = 350, experience = 45, cooldown = 600, minLevel = 10},
                {name = "Fragile Cargo", payment = 500, experience = 75, cooldown = 900, minLevel = 20}
            }
        },
        [2] = {
            name = "Mechanic",
            description = "Repair and customize vehicles",
            basePayment = 200,
            experienceMultiplier = 1.2,
            maxLevel = 75,
            unlockLevel = 5,
            requirements = {skill = "mechanic", level = 10},
            rewards = {
                [10] = {type = "tool", item = "advanced_wrench", message = "Advanced tools unlocked!"},
                [20] = {type = "access", feature = "engine_tuning", message = "Engine tuning unlocked!"},
                [35] = {type = "business", discount = 0.25, message = "25% discount on auto parts!"},
                [50] = {type = "workshop", location = "personal", message = "Personal workshop unlocked!"},
                [75] = {type = "title", title = "Master Mechanic", message = "You are now a Master Mechanic!"}
            },
            activities = {
                {name = "Basic Repair", payment = 150, experience = 20, cooldown = 180},
                {name = "Engine Overhaul", payment = 400, experience = 60, cooldown = 600, minLevel = 15},
                {name = "Custom Modification", payment = 750, experience = 100, cooldown = 1200, minLevel = 30}
            }
        },
        [3] = {
            name = "Police Officer",
            description = "Protect and serve the community",
            basePayment = 300,
            experienceMultiplier = 1.5,
            maxLevel = 100,
            unlockLevel = 10,
            requirements = {background_check = true, training = true},
            rewards = {
                [15] = {type = "weapon", weapon = "WEAPON_STUNGUN", message = "Taser authorized!"},
                [25] = {type = "vehicle", model = "police2", message = "Patrol car assigned!"},
                [40] = {type = "rank", rank = "Sergeant", message = "Promoted to Sergeant!"},
                [60] = {type = "access", feature = "swat_gear", message = "SWAT equipment authorized!"},
                [100] = {type = "title", title = "Police Chief", message = "You are now Police Chief!"}
            },
            activities = {
                {name = "Patrol Duty", payment = 250, experience = 30, cooldown = 600},
                {name = "Traffic Stop", payment = 100, experience = 15, cooldown = 120},
                {name = "Investigation", payment = 500, experience = 80, cooldown = 1800, minLevel = 20},
                {name = "SWAT Operation", payment = 1000, experience = 150, cooldown = 3600, minLevel = 50}
            }
        },
        [4] = {
            name = "Paramedic",
            description = "Save lives and provide medical care",
            basePayment = 250,
            experienceMultiplier = 1.3,
            maxLevel = 80,
            unlockLevel = 8,
            requirements = {skill = "medical", level = 15},
            rewards = {
                [12] = {type = "item", item = "advanced_medkit", message = "Advanced medical supplies unlocked!"},
                [25] = {type = "vehicle", model = "ambulance", message = "Ambulance assigned!"},
                [40] = {type = "access", feature = "surgery", message = "Surgical procedures unlocked!"},
                [65] = {type = "rank", rank = "Chief Paramedic", message = "Promoted to Chief Paramedic!"},
                [80] = {type = "title", title = "Life Saver", message = "You are now a certified Life Saver!"}
            },
            activities = {
                {name = "Emergency Response", payment = 300, experience = 40, cooldown = 300},
                {name = "Patient Transport", payment = 150, experience = 20, cooldown = 180},
                {name = "Surgery Assistance", payment = 600, experience = 90, cooldown = 1200, minLevel = 30},
                {name = "Disaster Response", payment = 800, experience = 120, cooldown = 2400, minLevel = 50}
            }
        },
        [5] = {
            name = "Business Owner",
            description = "Manage and grow your business empire",
            basePayment = 0,
            experienceMultiplier = 2.0,
            maxLevel = 150,
            unlockLevel = 25,
            requirements = {money = 50000, reputation = 100},
            rewards = {
                [20] = {type = "loan", amount = 100000, message = "Business loan approved!"},
                [35] = {type = "access", feature = "franchise", message = "Franchise opportunities unlocked!"},
                [50] = {type = "tax_break", percentage = 0.15, message = "15% tax reduction granted!"},
                [75] = {type = "influence", level = "city_council", message = "City council influence gained!"},
                [100] = {type = "monopoly", sector = "chosen", message = "Market monopoly achieved!"},
                [150] = {type = "title", title = "Business Tycoon", message = "You are now a Business Tycoon!"}
            },
            activities = {
                {name = "Manage Operations", payment = 500, experience = 50, cooldown = 1800},
                {name = "Negotiate Deals", payment = 1000, experience = 100, cooldown = 3600, minLevel = 20},
                {name = "Expand Business", payment = 2000, experience = 200, cooldown = 7200, minLevel = 40},
                {name = "Hostile Takeover", payment = 5000, experience = 500, cooldown = 14400, minLevel = 80}
            }
        }
    },
    
    playerJobData = {},
    activeJobs = {},
    jobCooldowns = {}
}

-- Initialize enhanced jobs tables
function initializeEnhancedJobsTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `enhanced_jobs` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `JobID` int(11) NOT NULL,
            `Level` int(11) DEFAULT 1,
            `Experience` int(11) DEFAULT 0,
            `TotalEarnings` int(11) DEFAULT 0,
            `CompletedTasks` int(11) DEFAULT 0,
            `Reputation` int(11) DEFAULT 0,
            `LastActivity` datetime DEFAULT CURRENT_TIMESTAMP,
            `UnlockedRewards` text DEFAULT NULL,
            `Achievements` text DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`CharacterID`) ON DELETE CASCADE,
            UNIQUE KEY `CharacterJob` (`CharacterID`, `JobID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `job_activities` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `JobID` int(11) NOT NULL,
            `ActivityName` varchar(64) NOT NULL,
            `Payment` int(11) NOT NULL,
            `Experience` int(11) NOT NULL,
            `CompletionTime` datetime DEFAULT CURRENT_TIMESTAMP,
            `QualityRating` int(2) DEFAULT 5,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`CharacterID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `job_leaderboards` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `JobID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `CharacterName` varchar(64) NOT NULL,
            `Level` int(11) NOT NULL,
            `TotalEarnings` int(11) NOT NULL,
            `CompletedTasks` int(11) NOT NULL,
            `LastUpdate` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            UNIQUE KEY `JobCharacter` (`JobID`, `CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("[SC:RP] Enhanced jobs tables initialized.")
end

-- Load player job data
function loadPlayerJobData(source, characterId)
    MySQL.Async.fetchAll("SELECT * FROM enhanced_jobs WHERE CharacterID = @characterId", {
        ['@characterId'] = characterId
    }, function(jobs)
        EnhancedJobs.playerJobData[source] = {}
        
        if jobs then
            for _, job in ipairs(jobs) do
                EnhancedJobs.playerJobData[source][job.JobID] = {
                    level = job.Level,
                    experience = job.Experience,
                    totalEarnings = job.TotalEarnings,
                    completedTasks = job.CompletedTasks,
                    reputation = job.Reputation,
                    unlockedRewards = job.UnlockedRewards and json.decode(job.UnlockedRewards) or {},
                    achievements = job.Achievements and json.decode(job.Achievements) or {}
                }
            end
        end
        
        -- Initialize default job data for jobs player hasn't started
        for jobId, jobData in pairs(EnhancedJobs.jobs) do
            if not EnhancedJobs.playerJobData[source][jobId] then
                EnhancedJobs.playerJobData[source][jobId] = {
                    level = 0,
                    experience = 0,
                    totalEarnings = 0,
                    completedTasks = 0,
                    reputation = 0,
                    unlockedRewards = {},
                    achievements = {}
                }
            end
        end
        
        print(("[SC:RP] Loaded job data for character %s"):format(characterId))
    end)
end

-- Start job activity
function startJobActivity(source, jobId, activityName)
    local player = PlayerData[source]
    if not player then return false end
    
    local job = EnhancedJobs.jobs[jobId]
    if not job then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid job ID.")
        return false
    end
    
    -- Find activity
    local activity = nil
    for _, act in ipairs(job.activities) do
        if act.name == activityName then
            activity = act
            break
        end
    end
    
    if not activity then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid activity.")
        return false
    end
    
    local playerJobData = EnhancedJobs.playerJobData[source][jobId]
    
    -- Check level requirement
    if activity.minLevel and playerJobData.level < activity.minLevel then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, 
            "You need level " .. activity.minLevel .. " for this activity.")
        return false
    end
    
    -- Check cooldown
    local cooldownKey = source .. "_" .. jobId .. "_" .. activityName
    if EnhancedJobs.jobCooldowns[cooldownKey] and os.time() < EnhancedJobs.jobCooldowns[cooldownKey] then
        local timeLeft = EnhancedJobs.jobCooldowns[cooldownKey] - os.time()
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 165, 0}, 
            "Activity on cooldown for " .. timeLeft .. " seconds.")
        return false
    end
    
    -- Check job requirements
    if not checkJobRequirements(source, job) then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You don't meet the job requirements.")
        return false
    end
    
    -- Start activity
    local activityId = "activity_" .. source .. "_" .. os.time()
    EnhancedJobs.activeJobs[activityId] = {
        source = source,
        jobId = jobId,
        activity = activity,
        startTime = os.time(),
        progress = 0
    }
    
    -- Set cooldown
    EnhancedJobs.jobCooldowns[cooldownKey] = os.time() + activity.cooldown
    
    -- Notify player and start activity
    TriggerClientEvent('chatMessage', source, "[JOBS]", {0, 255, 0}, 
        "Started: " .. activity.name .. " (Payment: $" .. activity.payment .. ")")
    
    TriggerClientEvent('scrp:startJobActivity', source, {
        activityId = activityId,
        jobId = jobId,
        activity = activity,
        estimatedTime = activity.cooldown
    })
    
    -- Start activity monitoring
    startActivityMonitoring(activityId)
    
    return true
end

-- Monitor job activity progress
function startActivityMonitoring(activityId)
    CreateThread(function()
        local jobData = EnhancedJobs.activeJobs[activityId]
        if not jobData then return end
        
        local duration = jobData.activity.cooldown
        local startTime = jobData.startTime
        
        while EnhancedJobs.activeJobs[activityId] and (os.time() - startTime) < duration do
            Wait(1000)
            
            local progress = ((os.time() - startTime) / duration) * 100
            jobData.progress = progress
            
            -- Send progress update
            TriggerClientEvent('scrp:updateJobProgress', jobData.source, activityId, progress)
            
            -- Random events during job
            if math.random(1, 100) <= 2 then -- 2% chance per second
                triggerJobEvent(jobData.source, jobData.jobId, jobData.activity)
            end
        end
        
        -- Complete activity
        if EnhancedJobs.activeJobs[activityId] then
            completeJobActivity(activityId)
        end
    end)
end

-- Complete job activity
function completeJobActivity(activityId)
    local jobData = EnhancedJobs.activeJobs[activityId]
    if not jobData then return end
    
    local source = jobData.source
    local player = PlayerData[source]
    if not player then return end
    
    local job = EnhancedJobs.jobs[jobData.jobId]
    local activity = jobData.activity
    local playerJobData = EnhancedJobs.playerJobData[source][jobData.jobId]
    
    -- Calculate rewards with bonuses
    local basePayment = activity.payment
    local levelBonus = math.floor(basePayment * (playerJobData.level * 0.02)) -- 2% per level
    local qualityRating = math.random(3, 10) -- Random quality rating
    local qualityBonus = math.floor(basePayment * (qualityRating * 0.05)) -- 5% per quality point
    
    local totalPayment = basePayment + levelBonus + qualityBonus
    local experience = activity.experience + math.floor(activity.experience * (qualityRating * 0.1))
    
    -- Award payment and experience
    player.Money = player.Money + totalPayment
    updatePlayerMoney(source)
    
    -- Update job data
    playerJobData.experience = playerJobData.experience + experience
    playerJobData.totalEarnings = playerJobData.totalEarnings + totalPayment
    playerJobData.completedTasks = playerJobData.completedTasks + 1
    playerJobData.reputation = playerJobData.reputation + math.floor(qualityRating / 2)
    
    -- Check for level up
    local experienceNeeded = playerJobData.level * 1000 * job.experienceMultiplier
    if playerJobData.experience >= experienceNeeded and playerJobData.level < job.maxLevel then
        playerJobData.level = playerJobData.level + 1
        playerJobData.experience = playerJobData.experience - experienceNeeded
        
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, 
            "LEVEL UP! " .. job.name .. " Level " .. playerJobData.level)
        
        -- Check for rewards
        checkJobRewards(source, jobData.jobId, playerJobData.level)
    end
    
    -- Log activity
    MySQL.Async.execute("INSERT INTO job_activities (CharacterID, JobID, ActivityName, Payment, Experience, QualityRating) VALUES (@characterId, @jobId, @activityName, @payment, @experience, @qualityRating)", {
        ['@characterId'] = player.CharacterID,
        ['@jobId'] = jobData.jobId,
        ['@activityName'] = activity.name,
        ['@payment'] = totalPayment,
        ['@experience'] = experience,
        ['@qualityRating'] = qualityRating
    })
    
    -- Save job data
    savePlayerJobData(source, jobData.jobId)
    
    -- Update leaderboard
    updateJobLeaderboard(source, jobData.jobId)
    
    -- Notify player
    TriggerClientEvent('chatMessage', source, "[JOBS]", {0, 255, 0}, 
        string.format("Activity completed! Payment: $%d (+$%d bonus) | XP: %d | Quality: %d/10", 
        basePayment, levelBonus + qualityBonus, experience, qualityRating))
    
    TriggerClientEvent('scrp:jobActivityCompleted', source, {
        payment = totalPayment,
        experience = experience,
        qualityRating = qualityRating,
        newLevel = playerJobData.level
    })
    
    -- Clean up
    EnhancedJobs.activeJobs[activityId] = nil
end

-- Check and award job rewards
function checkJobRewards(source, jobId, level)
    local job = EnhancedJobs.jobs[jobId]
    local playerJobData = EnhancedJobs.playerJobData[source][jobId]
    
    if job.rewards[level] and not playerJobData.unlockedRewards[tostring(level)] then
        local reward = job.rewards[level]
        playerJobData.unlockedRewards[tostring(level)] = true
        
        -- Award reward based on type
        if reward.type == "money" then
            PlayerData[source].Money = PlayerData[source].Money + reward.amount
            updatePlayerMoney(source)
        elseif reward.type == "vehicle" then
            -- Spawn vehicle for player
            TriggerClientEvent('scrp:awardVehicle', source, reward.model)
        elseif reward.type == "weapon" then
            -- Give weapon to player
            TriggerClientEvent('scrp:awardWeapon', source, reward.weapon)
        elseif reward.type == "skill" then
            -- Award skill experience
            addSkillExperience(source, reward.skill, reward.amount)
        elseif reward.type == "item" then
            -- Add item to inventory
            addItemToInventory(source, reward.item, 1)
        end
        
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, 
            "🎉 REWARD UNLOCKED: " .. reward.message)
        
        TriggerClientEvent('scrp:jobRewardUnlocked', source, {
            jobId = jobId,
            level = level,
            reward = reward
        })
    end
end

-- Check job requirements
function checkJobRequirements(source, job)
    local player = PlayerData[source]
    if not player then return false end
    
    -- Check level requirement
    if job.unlockLevel and player.Level < job.unlockLevel then
        return false
    end
    
    -- Check money requirement
    if job.requirements.money and player.Money < job.requirements.money then
        return false
    end
    
    -- Check skill requirement
    if job.requirements.skill then
        local skillLevel = getSkillLevel(source, job.requirements.skill)
        if skillLevel < job.requirements.level then
            return false
        end
    end
    
    -- Check reputation requirement
    if job.requirements.reputation then
        local totalReputation = 0
        for _, jobData in pairs(EnhancedJobs.playerJobData[source]) do
            totalReputation = totalReputation + jobData.reputation
        end
        if totalReputation < job.requirements.reputation then
            return false
        end
    end
    
    return true
end

-- Save player job data
function savePlayerJobData(source, jobId)
    local player = PlayerData[source]
    if not player then return end
    
    local jobData = EnhancedJobs.playerJobData[source][jobId]
    if not jobData then return end
    
    MySQL.Async.execute([[
        INSERT INTO enhanced_jobs (CharacterID, JobID, Level, Experience, TotalEarnings, CompletedTasks, Reputation, UnlockedRewards, Achievements)
        VALUES (@characterId, @jobId, @level, @experience, @totalEarnings, @completedTasks, @reputation, @unlockedRewards, @achievements)
        ON DUPLICATE KEY UPDATE
        Level = @level, Experience = @experience, TotalEarnings = @totalEarnings, 
        CompletedTasks = @completedTasks, Reputation = @reputation, 
        UnlockedRewards = @unlockedRewards, Achievements = @achievements, LastActivity = NOW()
    ]], {
        ['@characterId'] = player.CharacterID,
        ['@jobId'] = jobId,
        ['@level'] = jobData.level,
        ['@experience'] = jobData.experience,
        ['@totalEarnings'] = jobData.totalEarnings,
        ['@completedTasks'] = jobData.completedTasks,
        ['@reputation'] = jobData.reputation,
        ['@unlockedRewards'] = json.encode(jobData.unlockedRewards),
        ['@achievements'] = json.encode(jobData.achievements)
    })
end

-- Update job leaderboard
function updateJobLeaderboard(source, jobId)
    local player = PlayerData[source]
    if not player then return end
    
    local jobData = EnhancedJobs.playerJobData[source][jobId]
    if not jobData then return end
    
    MySQL.Async.execute([[
        INSERT INTO job_leaderboards (JobID, CharacterID, CharacterName, Level, TotalEarnings, CompletedTasks)
        VALUES (@jobId, @characterId, @characterName, @level, @totalEarnings, @completedTasks)
        ON DUPLICATE KEY UPDATE
        Level = @level, TotalEarnings = @totalEarnings, CompletedTasks = @completedTasks, LastUpdate = NOW()
    ]], {
        ['@jobId'] = jobId,
        ['@characterId'] = player.CharacterID,
        ['@characterName'] = player.Name,
        ['@level'] = jobData.level,
        ['@totalEarnings'] = jobData.totalEarnings,
        ['@completedTasks'] = jobData.completedTasks
    })
end

-- Trigger random job events
function triggerJobEvent(source, jobId, activity)
    local events = {
        {
            type = "bonus_opportunity",
            description = "Bonus opportunity available!",
            effect = function()
                local bonusPayment = math.floor(activity.payment * 0.5)
                PlayerData[source].Money = PlayerData[source].Money + bonusPayment
                updatePlayerMoney(source)
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 215, 0}, 
                    "Bonus earned: $" .. bonusPayment)
            end
        },
        {
            type = "skill_boost",
            description = "You're in the zone! Skill boost active.",
            effect = function()
                -- Temporary skill boost (could be implemented with client-side effects)
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {0, 255, 255}, 
                    "Skill boost active! +25% efficiency for next activity.")
            end
        },
        {
            type = "reputation_gain",
            description = "Your work impressed a client!",
            effect = function()
                local jobData = EnhancedJobs.playerJobData[source][jobId]
                jobData.reputation = jobData.reputation + 10
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 192, 203}, 
                    "Reputation increased! +10 reputation points.")
            end
        }
    }
    
    local event = events[math.random(1, #events)]
    TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 255, 0}, event.description)
    event.effect()
end

-- Initialize enhanced jobs system
function initializeEnhancedJobs()
    initializeEnhancedJobsTables()
    print("[SC:RP] Enhanced jobs system initialized.")
end

-- Event handlers
RegisterServerEvent('scrp:startJobActivity')
AddEventHandler('scrp:startJobActivity', function(jobId, activityName)
    startJobActivity(source, jobId, activityName)
end)

RegisterServerEvent('scrp:requestJobInfo')
AddEventHandler('scrp:requestJobInfo', function(jobId)
    local job = EnhancedJobs.jobs[jobId]
    if job then
        local playerJobData = EnhancedJobs.playerJobData[source] and EnhancedJobs.playerJobData[source][jobId]
        TriggerClientEvent('scrp:receiveJobInfo', source, job, playerJobData)
    end
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeEnhancedJobs()
    end
end)

-- Load job data when player loads character
AddEventHandler('scrp:playerLoaded', function(source, characterId)
    loadPlayerJobData(source, characterId)
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    if EnhancedJobs.playerJobData[source] then
        -- Save all job data before cleanup
        for jobId, _ in pairs(EnhancedJobs.playerJobData[source]) do
            savePlayerJobData(source, jobId)
        end
        EnhancedJobs.playerJobData[source] = nil
    end
    
    -- Clean up active jobs
    for activityId, jobData in pairs(EnhancedJobs.activeJobs) do
        if jobData.source == source then
            EnhancedJobs.activeJobs[activityId] = nil
        end
    end
end)
