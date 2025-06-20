-- server/enhanced_jobs.lua
-- Enhanced Job System with Progression and Rewards
-- Compatible with mysql-async 3.3.2 and FiveM artifact 16085

-- This table holds all the configuration for various jobs, including their details,
-- experience multipliers, maximum levels, unlock requirements, rewards, and activities.
EnhancedJobs = {
    jobs = {
        [1] = {
            name = "Delivery Driver",
            description = "Deliver packages across the city",
            basePayment = 150,
            experienceMultiplier = 1.0,
            maxLevel = 50,
            unlockLevel = 1,
            requirements = {}, -- No specific requirements to start this job
            rewards = {
                [5] = {type = "vehicle", model = "burrito", message = "Unlocked company van!"},
                [10] = {type = "money", amount = 5000, message = "Performance bonus: $5,000!"},
                [15] = {type = "skill", skill = "driving", amount = 100, message = "Driving skill boost!"},
                [25] = {type = "access", feature = "premium_routes", message = "Premium delivery routes unlocked!"},
                [50] = {type = "title", title = "Delivery Master", message = "You are now a Delivery Master!"}
            },
            activities = {
                {name = "Package Delivery", payment = 200, experience = 25, cooldown = 300}, -- 5 minutes cooldown
                {name = "Express Delivery", payment = 350, experience = 45, cooldown = 600, minLevel = 10}, -- 10 minutes cooldown
                {name = "Fragile Cargo", payment = 500, experience = 75, cooldown = 900, minLevel = 20} -- 15 minutes cooldown
            }
        },
        [2] = {
            name = "Mechanic",
            description = "Repair and customize vehicles",
            basePayment = 200,
            experienceMultiplier = 1.2,
            maxLevel = 75,
            unlockLevel = 5,
            requirements = {skill = "mechanic", level = 10}, -- Requires a certain skill level in 'mechanic'
            rewards = {
                [10] = {type = "tool", item = "advanced_wrench", message = "Advanced tools unlocked!"},
                [20] = {type = "access", feature = "engine_tuning", message = "Engine tuning unlocked!"},
                [35] = {type = "business", discount = 0.25, message = "25% discount on auto parts!"},
                [50] = {type = "workshop", location = "personal", message = "Personal workshop unlocked!"},
                [75] = {type = "title", title = "Master Mechanic", message = "You are now a Master Mechanic!"}
            },
            activities = {
                {name = "Basic Repair", payment = 150, experience = 20, cooldown = 180}, -- 3 minutes cooldown
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
            requirements = {background_check = true, training = true}, -- Example requirements
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
            basePayment = 0, -- Business owners earn passively or through specific activities, not base pay
            experienceMultiplier = 2.0,
            maxLevel = 150,
            unlockLevel = 25,
            requirements = {money = 50000, reputation = 100}, -- Significant investment to start
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

    -- Stores per-player job data (level, experience, earnings, etc.) keyed by source ID
    playerJobData = {},
    -- Stores currently active job activities, keyed by a unique activity ID
    activeJobs = {},
    -- Stores cooldown timers for job activities, keyed by a combination of player source, job ID, and activity name
    jobCooldowns = {}
}

-- Assumed external functions/data (replace with your framework's actual implementations)
-- PlayerData: A global or accessible table holding player data (e.g., Money, CharacterID, Name, Level)
-- TriggerClientEvent: FiveM function to trigger client-side events
-- MySQL.Async: Assumed library for asynchronous MySQL queries
-- json.encode/decode: Assumed functions for JSON serialization/deserialization

-- Placeholder for framework-specific functions
-- You will need to replace these with actual implementations from your FiveM framework (e.g., ESX, QBCore)
local PlayerData = PlayerData or {} -- Placeholder, replace with your actual PlayerData management
function updatePlayerMoney(source)
    -- This function should update the player's money on the client and potentially save to DB
    TriggerClientEvent('scrp:updateMoney', source, PlayerData[source].Money)
    print(("[SC:RP] Player %s money updated to %s"):format(GetPlayerName(source), PlayerData[source].Money))
end

function getSkillLevel(source, skillName)
    -- This function should return the player's skill level for a given skill
    -- Example: if PlayerData[source].Skills existed
    -- return PlayerData[source].Skills[skillName] or 0
    print(("[SC:RP] Getting skill level for %s: %s"):format(GetPlayerName(source), skillName))
    return 0 -- Placeholder: always return 0, replace with actual skill system
end

function addSkillExperience(source, skillName, amount)
    -- This function should add experience to a player's skill
    print(("[SC:RP] Adding %s XP to skill %s for %s"):format(amount, skillName, GetPlayerName(source)))
    -- Example: PlayerData[source].Skills[skillName] = (PlayerData[source].Skills[skillName] or 0) + amount
end

function addItemToInventory(source, itemName, count)
    -- This function should add an item to the player's inventory
    print(("[SC:RP] Adding %s x%s to inventory for %s"):format(itemName, count, GetPlayerName(source)))
end
-- End of assumed external functions/data

-- Function to initialize necessary database tables for the enhanced job system.
-- This creates 'enhanced_jobs' for player job progression, 'job_activities' for logging completed tasks,
-- and 'job_leaderboards' for tracking top performers.
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
            `UnlockedRewards` text DEFAULT NULL, -- Stores JSON encoded table of unlocked rewards
            `Achievements` text DEFAULT NULL, -- Stores JSON encoded table of achievements
            PRIMARY KEY (`ID`),
            -- Assumes a 'characters' table with a 'CharacterID' primary key exists
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`CharacterID`) ON DELETE CASCADE,
            UNIQUE KEY `CharacterJob` (`CharacterID`, `JobID`) -- Ensures only one entry per character per job
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function() -- Empty parameters table as there are no direct @params
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
        ]], {}, function()
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
            ]], {}, function()
                print("[SC:RP] Enhanced jobs tables initialized.")
            end)
        end)
    end)
end


-- Function to load a player's job data from the database.
-- This is typically called when a player joins the server or loads their character.
function loadPlayerJobData(source, characterId)
    MySQL.Async.fetchAll("SELECT * FROM enhanced_jobs WHERE CharacterID = @characterId", {
        ['@characterId'] = characterId
    }, function(jobs)
        EnhancedJobs.playerJobData[source] = {}

        if jobs then
            for _, job in ipairs(jobs) do
                -- Decode JSON stored rewards and achievements
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

        -- Initialize default job data for jobs the player hasn't started yet.
        -- This ensures every job has a default entry in the player's data structure,
        -- even if they are at level 0 for it.
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

        print(("[SC:RP] Loaded job data for character %s (Player Source: %s)"):format(characterId, source))
    end)
end

-- Function to start a specific job activity for a player.
-- Performs checks for job validity, activity validity, level requirements, cooldowns, and job-specific requirements.
function startJobActivity(source, jobId, activityName)
    local player = PlayerData[source] -- Get player data from your framework
    if not player then return false end

    local job = EnhancedJobs.jobs[jobId]
    if not job then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Invalid job ID.")
        return false
    end

    -- Find the specific activity within the job's activities
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

    -- Check if the player meets the minimum level requirement for this activity
    if activity.minLevel and playerJobData.level < activity.minLevel then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0},
            "You need level " .. activity.minLevel .. " in " .. job.name .. " for this activity.")
        return false
    end

    -- Check activity cooldown
    local cooldownKey = source .. "_" .. jobId .. "_" .. activityName
    if EnhancedJobs.jobCooldowns[cooldownKey] and os.time() < EnhancedJobs.jobCooldowns[cooldownKey] then
        local timeLeft = EnhancedJobs.jobCooldowns[cooldownKey] - os.time()
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 165, 0},
            "Activity on cooldown for " .. timeLeft .. " seconds.")
        return false
    end

    -- Check overall job unlock requirements
    if not checkJobRequirements(source, job) then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You don't meet the job requirements to start this activity.")
        return false
    end

    -- Create a unique ID for this active job instance
    local activityId = "activity_" .. source .. "_" .. os.time()
    EnhancedJobs.activeJobs[activityId] = {
        source = source,
        jobId = jobId,
        activity = activity,
        startTime = os.time(),
        progress = 0
    }

    -- Set the cooldown for this specific activity
    EnhancedJobs.jobCooldowns[cooldownKey] = os.time() + activity.cooldown

    -- Notify the player and trigger client-side activity initiation
    TriggerClientEvent('chatMessage', source, "[JOBS]", {0, 255, 0},
        "Started: " .. activity.name .. " (Estimated Payment: $" .. activity.payment .. ")")

    TriggerClientEvent('scrp:startJobActivity', source, {
        activityId = activityId,
        jobId = jobId,
        activity = activity,
        estimatedTime = activity.cooldown -- Time in seconds for client display
    })

    -- Start server-side monitoring for the activity
    startActivityMonitoring(activityId)

    return true
end

-- Function to monitor the progress of a running job activity.
-- This runs in a separate thread and sends progress updates to the client.
-- It also has a chance to trigger random in-job events.
function startActivityMonitoring(activityId)
    CreateThread(function()
        local jobData = EnhancedJobs.activeJobs[activityId]
        if not jobData then return end -- If job was cancelled or completed externally

        local duration = jobData.activity.cooldown
        local startTime = jobData.startTime

        while EnhancedJobs.activeJobs[activityId] and (os.time() - startTime) < duration do
            Wait(1000) -- Wait for 1 second before updating progress

            local elapsedTime = os.time() - startTime
            local progress = math.min(100, math.floor((elapsedTime / duration) * 100)) -- Progress from 0-100%
            jobData.progress = progress

            -- Send progress update to the client
            TriggerClientEvent('scrp:updateJobProgress', jobData.source, activityId, progress)

            -- Random events during job: 2% chance per second for an event to occur
            if math.random(1, 100) <= 2 then
                triggerJobEvent(jobData.source, jobData.jobId, jobData.activity)
            end
        end

        -- If the activity is still active after the duration, complete it
        if EnhancedJobs.activeJobs[activityId] then
            completeJobActivity(activityId)
        end
    end)
end

-- Function to complete a job activity and award rewards.
-- Calculates payment and experience, updates player data, checks for level-ups and rewards,
-- logs the activity, saves data, and updates leaderboards.
function completeJobActivity(activityId)
    local jobData = EnhancedJobs.activeJobs[activityId]
    if not jobData then return end

    local source = jobData.source
    local player = PlayerData[source]
    if not player then return end

    local job = EnhancedJobs.jobs[jobData.jobId]
    local activity = jobData.activity
    local playerJobData = EnhancedJobs.playerJobData[source][jobData.jobId]

    -- Calculate total payment with bonuses
    local basePayment = activity.payment
    -- Level bonus: 2% additional payment per job level
    local levelBonus = math.floor(basePayment * (playerJobData.level * 0.02))
    -- Random quality rating for the completed activity (3 to 10)
    local qualityRating = math.random(3, 10)
    -- Quality bonus: 5% additional payment per quality point
    local qualityBonus = math.floor(basePayment * (qualityRating * 0.05))

    local totalPayment = basePayment + levelBonus + qualityBonus
    -- Experience calculation: base experience + 10% per quality point
    local experience = activity.experience + math.floor(activity.experience * (qualityRating * 0.1))

    -- Award payment to the player
    player.Money = player.Money + totalPayment
    updatePlayerMoney(source) -- Update money on client and save to DB

    -- Update player's job-specific data
    playerJobData.experience = playerJobData.experience + experience
    playerJobData.totalEarnings = playerJobData.totalEarnings + totalPayment
    playerJobData.completedTasks = playerJobData.completedTasks + 1
    -- Reputation gain based on quality rating
    playerJobData.reputation = playerJobData.reputation + math.floor(qualityRating / 2)

    -- Check for level up
    -- Experience needed for next level: Current Level * 1000 * Job's Experience Multiplier
    local experienceNeeded = playerJobData.level * 1000 * job.experienceMultiplier
    if playerJobData.experience >= experienceNeeded and playerJobData.level < job.maxLevel then
        playerJobData.level = playerJobData.level + 1
        playerJobData.experience = playerJobData.experience - experienceNeeded -- Carry over excess experience

        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0},
            "LEVEL UP! " .. job.name .. " Level " .. playerJobData.level .. "!")

        -- Check for rewards associated with the new level
        checkJobRewards(source, jobData.jobId, playerJobData.level)
    end

    -- Log the completed activity to the 'job_activities' table
    MySQL.Async.execute("INSERT INTO job_activities (CharacterID, JobID, ActivityName, Payment, Experience, QualityRating) VALUES (@characterId, @jobId, @activityName, @payment, @experience, @qualityRating)", {
        ['@characterId'] = player.CharacterID,
        ['@jobId'] = jobData.jobId,
        ['@activityName'] = activity.name,
        ['@payment'] = totalPayment,
        ['@experience'] = experience,
        ['@qualityRating'] = qualityRating
    })

    -- Save the updated player job data to the 'enhanced_jobs' table
    savePlayerJobData(source, jobData.jobId)

    -- Update the job leaderboards
    updateJobLeaderboard(source, jobData.jobId)

    -- Notify the player about activity completion and rewards
    TriggerClientEvent('chatMessage', source, "[JOBS]", {0, 255, 0},
        string.format("Activity completed! Payment: $%d (+$%d bonus) | XP: %d | Quality: %d/10",
        basePayment, levelBonus + qualityBonus, experience, qualityRating))

    TriggerClientEvent('scrp:jobActivityCompleted', source, {
        payment = totalPayment,
        experience = experience,
        qualityRating = qualityRating,
        newLevel = playerJobData.level
    })

    -- Clean up the active job entry
    EnhancedJobs.activeJobs[activityId] = nil
end

-- Function to check and award rewards when a player reaches a certain job level.
-- Rewards can be money, vehicles, weapons, skill boosts, items, access to features, titles, etc.
function checkJobRewards(source, jobId, level)
    local job = EnhancedJobs.jobs[jobId]
    local playerJobData = EnhancedJobs.playerJobData[source][jobId]

    -- Check if there's a reward defined for this level and if it hasn't been unlocked yet
    if job.rewards[level] and not playerJobData.unlockedRewards[tostring(level)] then
        local reward = job.rewards[level]
        playerJobData.unlockedRewards[tostring(level)] = true -- Mark reward as unlocked

        -- Apply the reward based on its type
        if reward.type == "money" then
            PlayerData[source].Money = PlayerData[source].Money + reward.amount
            updatePlayerMoney(source)
        elseif reward.type == "vehicle" then
            -- Trigger client event to spawn/award vehicle
            TriggerClientEvent('scrp:awardVehicle', source, reward.model)
        elseif reward.type == "weapon" then
            -- Trigger client event to give weapon
            TriggerClientEvent('scrp:awardWeapon', source, reward.weapon)
        elseif reward.type == "skill" then
            -- Use the assumed addSkillExperience function
            addSkillExperience(source, reward.skill, reward.amount)
        elseif reward.type == "item" then
            -- Use the assumed addItemToInventory function
            addItemToInventory(source, reward.item, 1)
        -- Add more reward types as needed (e.g., 'access', 'rank', 'title', 'business', 'loan', 'tax_break', 'influence', 'monopoly')
        -- These might require more complex framework integrations
        elseif reward.type == "access" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, "New access granted: " .. reward.feature)
        elseif reward.type == "rank" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, "New rank achieved: " .. reward.rank)
        elseif reward.type == "title" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, "New title earned: " .. reward.title)
        elseif reward.type == "business" then
             TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, "Business bonus: " .. reward.message)
        elseif reward.type == "loan" then
            PlayerData[source].Money = PlayerData[source].Money + reward.amount
            updatePlayerMoney(source)
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, reward.message)
        elseif reward.type == "tax_break" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, reward.message)
        elseif reward.type == "influence" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, reward.message)
        elseif reward.type == "monopoly" then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 215, 0}, reward.message)
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

-- Function to check if a player meets all the requirements to start a particular job.
-- This includes overall player level, money, specific skill levels, and total reputation.
function checkJobRequirements(source, job)
    local player = PlayerData[source]
    if not player then return false end

    -- Check global player level requirement to unlock the job
    if job.unlockLevel and player.Level < job.unlockLevel then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You need player level " .. job.unlockLevel .. " to unlock this job.")
        return false
    end

    -- Check money requirement
    if job.requirements.money and player.Money < job.requirements.money then
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You need $" .. job.requirements.money .. " to unlock this job.")
        return false
    end

    -- Check skill requirement
    if job.requirements.skill then
        local skillLevel = getSkillLevel(source, job.requirements.skill)
        if skillLevel < job.requirements.level then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You need " .. job.requirements.skill .. " skill level " .. job.requirements.level .. " to unlock this job.")
            return false
        end
    end

    -- Check total reputation requirement across all jobs
    if job.requirements.reputation then
        local totalReputation = 0
        -- Sum up reputation from all jobs the player has engaged in
        if EnhancedJobs.playerJobData[source] then
            for _, jobData in pairs(EnhancedJobs.playerJobData[source]) do
                totalReputation = totalReputation + jobData.reputation
            end
        end
        if totalReputation < job.requirements.reputation then
            TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "You need " .. job.requirements.reputation .. " total reputation to unlock this job.")
            return false
        end
    end

    -- Add checks for 'background_check' or 'training' requirements if implemented elsewhere
    -- Example: if job.requirements.background_check and not player.HasBackgroundCheck then return false end

    return true -- All requirements met
end

-- Function to save a player's job-specific data to the database.
-- Uses `INSERT ... ON DUPLICATE KEY UPDATE` to either create a new record or update an existing one.
function savePlayerJobData(source, jobId)
    local player = PlayerData[source]
    if not player then return end

    local jobData = EnhancedJobs.playerJobData[source][jobId]
    if not jobData then return end

    MySQL.Async.execute([[
        INSERT INTO enhanced_jobs (CharacterID, JobID, Level, Experience, TotalEarnings, CompletedTasks, Reputation, UnlockedRewards, Achievements, LastActivity)
        VALUES (@characterId, @jobId, @level, @experience, @totalEarnings, @completedTasks, @reputation, @unlockedRewards, @achievements, NOW())
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
        ['@unlockedRewards'] = json.encode(jobData.unlockedRewards), -- Encode table to JSON string
        ['@achievements'] = json.encode(jobData.achievements) -- Encode table to JSON string
    }, function(rowsAffected)
        if rowsAffected > 0 then
            -- print(("[SC:RP] Saved job data for character %s, JobID %s"):format(player.CharacterID, jobId))
        else
            print(("[SC:RP] Failed to save job data for character %s, JobID %s"):format(player.CharacterID, jobId))
        end
    end)
end

-- Function to update the job leaderboards.
-- This ensures that player progression is reflected on a global leaderboard.
function updateJobLeaderboard(source, jobId)
    local player = PlayerData[source]
    if not player then return end

    local jobData = EnhancedJobs.playerJobData[source][jobId]
    if not jobData then return end

    MySQL.Async.execute([[
        INSERT INTO job_leaderboards (JobID, CharacterID, CharacterName, Level, TotalEarnings, CompletedTasks, LastUpdate)
        VALUES (@jobId, @characterId, @characterName, @level, @totalEarnings, @completedTasks, NOW())
        ON DUPLICATE KEY UPDATE
        Level = @level, TotalEarnings = @totalEarnings, CompletedTasks = @completedTasks, LastUpdate = NOW()
    ]], {
        ['@jobId'] = jobId,
        ['@characterId'] = player.CharacterID,
        ['@characterName'] = player.Name, -- Assumes PlayerData[source].Name exists
        ['@level'] = jobData.level,
        ['@totalEarnings'] = jobData.totalEarnings,
        ['@completedTasks'] = jobData.completedTasks
    }, function(rowsAffected)
        if rowsAffected > 0 then
            -- print(("[SC:RP] Updated leaderboard for character %s, JobID %s"):format(player.CharacterID, jobId))
        else
            print(("[SC:RP] Failed to update leaderboard for character %s, JobID %s"):format(player.CharacterID, jobId))
        end
    end)
end

-- Function to trigger a random event during an active job activity.
-- These events can provide bonuses or other dynamic interactions.
function triggerJobEvent(source, jobId, activity)
    local events = {
        {
            type = "bonus_opportunity",
            description = "A sudden opportunity arises! Bonus payment awaits!",
            effect = function()
                local bonusPayment = math.floor(activity.payment * 0.5) -- 50% of activity's base payment
                PlayerData[source].Money = PlayerData[source].Money + bonusPayment
                updatePlayerMoney(source)
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 215, 0},
                    "Bonus earned: $" .. bonusPayment .. "!")
            end
        },
        {
            type = "skill_boost",
            description = "You're in the zone! Feeling more efficient.",
            effect = function()
                -- This could temporarily increase experience gain or reduce cooldowns for the current activity
                -- For now, just a notification. A real implementation would involve temporary buffs.
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {0, 255, 255},
                    "Skill boost active! You might perform better for a short period.")
            end
        },
        {
            type = "reputation_gain",
            description = "Your excellent work impressed a client!",
            effect = function()
                local jobData = EnhancedJobs.playerJobData[source][jobId]
                jobData.reputation = jobData.reputation + 10 -- Award 10 reputation points
                TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 192, 203},
                    "Reputation increased! +10 reputation points.")
            end
        },
        {
            type = "minor_setback",
            description = "Uh oh, a minor setback! Activity might take longer.",
            effect = function()
                local currentActivity = EnhancedJobs.activeJobs["activity_" .. source .. "_" .. jobData.startTime] -- Re-evaluate
                if currentActivity then
                    -- Increase remaining time by 10%
                    local timeToAdd = currentActivity.activity.cooldown * 0.1
                    currentActivity.startTime = currentActivity.startTime - timeToAdd -- Effectively extends duration
                    TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 0, 0}, "Activity extended slightly!")
                end
            end
        }
    }

    local event = events[math.random(1, #events)] -- Randomly pick an event
    TriggerClientEvent('chatMessage', source, "[JOB EVENT]", {255, 255, 0}, event.description)
    event.effect() -- Execute the event's effect
end


-- Main initialization function for the enhanced job system.
function initializeEnhancedJobs()
    initializeEnhancedJobsTables() -- Ensure DB tables are ready
    print("[SC:RP] Enhanced jobs system initialized.")
end

-- Server Event Handlers
-- These listen for events triggered from the client-side or other server-side scripts.

-- Handles client request to start a job activity.
RegisterServerEvent('scrp:startJobActivity')
AddEventHandler('scrp:startJobActivity', function(jobId, activityName)
    startJobActivity(source, jobId, activityName)
end)

-- Handles client request for information about a specific job.
RegisterServerEvent('scrp:requestJobInfo')
AddEventHandler('scrp:requestJobInfo', function(requestedJobId)
    local job = EnhancedJobs.jobs[requestedJobId]
    if job then
        -- Get player's specific data for this job, if it exists
        local playerJobData = EnhancedJobs.playerJobData[source] and EnhancedJobs.playerJobData[source][requestedJobId]
        TriggerClientEvent('scrp:receiveJobInfo', source, job, playerJobData)
    else
        TriggerClientEvent('chatMessage', source, "[JOBS]", {255, 0, 0}, "Requested job information not found.")
    end
end)

-- Resource lifecycle event: Called when the resource starts.
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeEnhancedJobs()
    end
end)

-- Custom event: Assumed to be triggered by your framework when a player successfully loads their character.
-- This is crucial for loading the player's job progression data from the database.
AddEventHandler('scrp:playerLoaded', function(characterId)
    -- The 'source' global variable is automatically available in server-side event handlers
    loadPlayerJobData(source, characterId)
    -- Also, ensure PlayerData for this source is populated by your framework here
    -- For demonstration, assuming PlayerData[source] is filled by the time this event fires
    -- Example: PlayerData[source] = your_framework_get_player_data_function(source)
end)

-- Player disconnect event: Called when a player leaves the server.
-- This ensures all unsaved job data for the disconnecting player is persisted to the database.
AddEventHandler('playerDropped', function()
    -- Get the source ID of the disconnecting player
    local source = source

    -- Save all job data for this player before cleaning up
    if EnhancedJobs.playerJobData[source] then
        for jobId, _ in pairs(EnhancedJobs.playerJobData[source]) do
            savePlayerJobData(source, jobId)
        end
        EnhancedJobs.playerJobData[source] = nil -- Clear player's data from memory
    end

    -- Clean up any active job activities for this player
    for activityId, jobData in pairs(EnhancedJobs.activeJobs) do
        if jobData.source == source then
            EnhancedJobs.activeJobs[activityId] = nil
        end
    end

    -- Clean up cooldowns for this player
    for cooldownKey, _ in pairs(EnhancedJobs.jobCooldowns) do
        if string.find(cooldownKey, source .. "_") == 1 then -- Check if key starts with player's source
            EnhancedJobs.jobCooldowns[cooldownKey] = nil
        end
    end

    print(("[SC:RP] Cleaned up job data for player source %s"):format(source))
end)

