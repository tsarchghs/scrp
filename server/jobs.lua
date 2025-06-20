-- Job system

Jobs = {
    [1] = {Name = "Unemployed", Salary = 0},
    [2] = {Name = "Taxi Driver", Salary = 50},
    [3] = {Name = "Bus Driver", Salary = 75},
    [4] = {Name = "Trucker", Salary = 100},
    [5] = {Name = "Mechanic", Salary = 125},
    [6] = {Name = "Medic", Salary = 150},
    [7] = {Name = "Police Officer", Salary = 200}
}

-- Function to set player job
function setPlayerJob(source, jobId)
    if not PlayerData[source] then return end
    if not Jobs[jobId] then return end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        UPDATE `characters` SET `JobID` = @jobId WHERE `ID` = @characterId
    ]]

    MySQL.query(query, {
        ['@jobId'] = jobId,
        ['@characterId'] = characterId
    }, function(rows, affected)
        if affected > 0 then
            PlayerData[source].JobID = jobId
            TriggerClientEvent('chatMessage', source, "[JOB]", { 0, 255, 255 }, 
                ("Your job has been set to %s"):format(Jobs[jobId].Name))
        end
    end)
end

-- Function to pay job salary
function payJobSalary()
    for source, data in pairs(PlayerData) do
        if data.JobID and Jobs[data.JobID] then
            local salary = Jobs[data.JobID].Salary
            if salary > 0 then
                data.Money = data.Money + salary
                TriggerClientEvent('chatMessage', source, "[PAYCHECK]", { 0, 255, 0 }, 
                    ("You received $%d salary from your job as %s"):format(salary, Jobs[data.JobID].Name))
            end
        end
    end
end

-- Pay salaries every 30 minutes
CreateThread(function()
    while true do
        Wait(1800000) -- 30 minutes
        payJobSalary()
    end
end)
