-- Skill system for SC:RP FiveM

Skills = {
    ["strength"] = {name = "Strength", maxLevel = 100, xpPerLevel = 1000},
    ["stamina"] = {name = "Stamina", maxLevel = 100, xpPerLevel = 1000},
    ["driving"] = {name = "Driving", maxLevel = 100, xpPerLevel = 1000},
    ["shooting"] = {name = "Shooting", maxLevel = 100, xpPerLevel = 1000},
    ["fishing"] = {name = "Fishing", maxLevel = 100, xpPerLevel = 1000},
    ["crafting"] = {name = "Crafting", maxLevel = 100, xpPerLevel = 1000},
    ["cooking"] = {name = "Cooking", maxLevel = 100, xpPerLevel = 1000},
    ["mechanic"] = {name = "Mechanic", maxLevel = 100, xpPerLevel = 1000},
    ["lockpicking"] = {name = "Lockpicking", maxLevel = 100, xpPerLevel = 1000},
    ["stealth"] = {name = "Stealth", maxLevel = 100, xpPerLevel = 1000}
}

PlayerSkills = {}

-- Initialize skills table
function initializeSkillsTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `character_skills` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `SkillName` varchar(32) NOT NULL,
            `Level` int(3) DEFAULT 1,
            `Experience` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `CharacterSkill` (`CharacterID`, `SkillName`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to load player skills
function loadPlayerSkills(source, characterId)
    local query = [[
        SELECT * FROM `character_skills` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        PlayerSkills[source] = {}
        
        -- Initialize all skills with default values
        for skillName, skillData in pairs(Skills) do
            PlayerSkills[source][skillName] = {
                name = skillData.name,
                level = 1,
                experience = 0,
                maxLevel = skillData.maxLevel,
                xpPerLevel = skillData.xpPerLevel
            }
        end
        
        -- Override with database values
        for i = 1, #rows do
            local skill = rows[i]
            if Skills[skill.SkillName] then
                PlayerSkills[source][skill.SkillName].level = skill.Level
                PlayerSkills[source][skill.SkillName].experience = skill.Experience
            end
        end
        
        -- Send skills to client
        TriggerClientEvent('scrp:updateSkills', source, PlayerSkills[source])
    end)
end

-- Function to save player skills
function savePlayerSkills(source)
    if not PlayerData[source] or not PlayerSkills[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    
    for skillName, skillData in pairs(PlayerSkills[source]) do
        local query = [[
            INSERT INTO `character_skills` (`CharacterID`, `SkillName`, `Level`, `Experience`)
            VALUES (@characterId, @skillName, @level, @experience)
            ON DUPLICATE KEY UPDATE `Level` = @level, `Experience` = @experience
        ]]

        MySQL.query(query, {
            ['@characterId'] = characterId,
            ['@skillName'] = skillName,
            ['@level'] = skillData.level,
            ['@experience'] = skillData.experience
        })
    end
end

-- Function to add skill experience
function addSkillExperience(source, skillName, amount)
    if not PlayerData[source] or not PlayerSkills[source] or not Skills[skillName] then return end
    
    local skill = PlayerSkills[source][skillName]
    if skill.level >= skill.maxLevel then return end
    
    skill.experience = skill.experience + amount
    
    -- Check for level up
    local xpNeeded = skill.level * skill.xpPerLevel
    if skill.experience >= xpNeeded then
        skill.level = skill.level + 1
        skill.experience = skill.experience - xpNeeded
        
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 0, 255, 0 }, 
            ("Your %s skill increased to level %d!"):format(skill.name, skill.level))
    end
    
    -- Update client
    TriggerClientEvent('scrp:updateSkills', source, PlayerSkills[source])
end

-- Function to get skill level
function getSkillLevel(source, skillName)
    if not PlayerData[source] or not PlayerSkills[source] or not Skills[skillName] then return 1 end
    return PlayerSkills[source][skillName].level
end

-- Function to get skill success chance
function getSkillSuccessChance(source, skillName, difficulty)
    if not PlayerData[source] or not PlayerSkills[source] or not Skills[skillName] then return 0 end
    
    local level = PlayerSkills[source][skillName].level
    local chance = (level / difficulty) * 100
    
    -- Cap between 5% and 95%
    if chance < 5 then chance = 5 end
    if chance > 95 then chance = 95 end
    
    return chance
end

-- Function to check skill success
function checkSkillSuccess(source, skillName, difficulty)
    local chance = getSkillSuccessChance(source, skillName, difficulty)
    local roll = math.random(1, 100)
    
    local success = roll <= chance
    if success then
        -- Add experience on success
        addSkillExperience(source, skillName, math.floor(difficulty * 10))
    else
        -- Add small experience on failure
        addSkillExperience(source, skillName, math.floor(difficulty * 2))
    end
    
    return success
end

-- Skill-based actions
function performStrengthAction(source)
    local success = checkSkillSuccess(source, "strength", 10)
    if success then
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 0, 255, 0 }, "You successfully performed a strength action!")
    else
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 255, 0, 0 }, "You failed to perform a strength action!")
    end
end

function performDrivingAction(source, difficulty)
    local success = checkSkillSuccess(source, "driving", difficulty)
    if success then
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 0, 255, 0 }, "You successfully performed a driving maneuver!")
    else
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 255, 0, 0 }, "You failed to perform a driving maneuver!")
    end
end

function performShootingAction(source, difficulty)
    local success = checkSkillSuccess(source, "shooting", difficulty)
    return success -- Return success for hit calculation
end

function performLockpickingAction(source, difficulty)
    local success = checkSkillSuccess(source, "lockpicking", difficulty)
    if success then
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 0, 255, 0 }, "You successfully picked the lock!")
    else
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 255, 0, 0 }, "You failed to pick the lock!")
    end
    return success
end

-- Passive skill gain
CreateThread(function()
    while true do
        Wait(60000) -- 1 minute
        
        for source, data in pairs(PlayerData) do
            if PlayerSkills[source] then
                -- Driving skill gain when in vehicle
                local ped = GetPlayerPed(source)
                if IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if GetPedInVehicleSeat(vehicle, -1) == ped then -- If driver
                        addSkillExperience(source, "driving", 5)
                    end
                end
                
                -- Stamina skill gain when running
                if IsPedRunning(ped) then
                    addSkillExperience(source, "stamina", 3)
                end
            end
        end
    end
end)
