-- Advanced Housing Commands for South Central Roleplay
-- Compatible with mysql-async 3.3.2 and FiveM artifact 15859
-- Author: SC:RP Development Team

-- House management commands
RegisterCommand('buyhouse', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/buyhouse [house_id]")
        return
    end
    
    local houseId = tonumber(args[1])
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid house ID.")
        return
    end
    
    buyHouse(source, houseId)
end, false)

RegisterCommand('sellhouse', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to sell it.")
        return
    end
    
    sellHouse(source, houseId)
end, false)

RegisterCommand('lock', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    -- Find nearest house
    local nearestHouse = nil
    local nearestDistance = 999999
    
    for houseId, house in pairs(AdvancedHouses) do
        local distance = #(vector3(player.Position.x, player.Position.y, player.Position.z) - vector3(house.ExteriorX, house.ExteriorY, house.ExteriorZ))
        if distance < nearestDistance and distance <= 5.0 then
            nearestDistance = distance
            nearestHouse = houseId
        end
    end
    
    if nearestHouse then
        toggleHouseLock(source, nearestHouse)
    else
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You're not near any house.")
    end
end, false)

RegisterCommand('enter', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    -- Find nearest house
    local nearestHouse = nil
    local nearestDistance = 999999
    
    for houseId, house in pairs(AdvancedHouses) do
        local distance = #(vector3(player.Position.x, player.Position.y, player.Position.z) - vector3(house.ExteriorX, house.ExteriorY, house.ExteriorZ))
        if distance < nearestDistance and distance <= 5.0 then
            nearestDistance = distance
            nearestHouse = houseId
        end
    end
    
    if nearestHouse then
        enterHouse(source, nearestHouse)
    else
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You're not near any house.")
    end
end, false)

RegisterCommand('exit', function(source, args)
    exitHouse(source)
end, false)

RegisterCommand('houseinfo', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    local houseId = PlayerInHouse[source]
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[HOUSE]", {255, 0, 0}, "You need to be inside a house to view its information.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then return end
    
    -- Get owner name
    MySQL.query("SELECT Name FROM characters WHERE ID = @ownerId", {
        ['@ownerId'] = house.OwnerID
    }, function(owners)
        local ownerName = "None"
        if owners and #owners > 0 then
            ownerName = owners[1].Name
        end
        
        -- Get furniture count
        MySQL.query("SELECT COUNT(*) as count FROM house_furniture WHERE HouseID = @houseId", {
            ['@houseId'] = houseId
        }, function(result)
            local furnitureCount = result[1].count
            
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {0, 255, 255}, "=== House Information ===")
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Name: " .. house.Name)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Owner: " .. ownerName)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Price: $" .. house.Price)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Level: " .. house.Level)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Furniture: " .. furnitureCount .. "/" .. house.MaxFurniture)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Security Level: " .. house.SecurityLevel)
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Status: " .. (house.Locked == 1 and "Locked" or "Unlocked"))
            TriggerClientEvent('chatMessage', source, "[HOUSE INFO]", {255, 255, 255}, "Description: " .. house.Description)
        end)
    end)
end, false)

RegisterCommand('setdescription', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/setdescription [description]")
        return
    end
    
    local description = table.concat(args, " ")
    setHouseDescription(source, description)
end, false)

RegisterCommand('sethousename', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/sethousename [name]")
        return
    end
    
    local name = table.concat(args, " ")
    setHouseName(source, name)
end, false)

RegisterCommand('addroommate', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/addroommate [player_id]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid player ID.")
        return
    end
    
    addRoommate(source, targetId)
end, false)

RegisterCommand('removeroommate', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/removeroommate [player_id]")
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid player ID.")
        return
    end
    
    removeRoommate(source, targetId)
end, false)

RegisterCommand('upgradehouse', function(source, args)
    upgradeHouse(source)
end, false)

RegisterCommand('paymaintenance', function(source, args)
    payHouseMaintenance(source)
end, false)

RegisterCommand('forsale', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/forsale [price]")
        return
    end
    
    local price = tonumber(args[1])
    if not price or price < 1000 then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid price. Minimum $1,000.")
        return
    end
    
    setHouseForSale(source, price)
end, false)

RegisterCommand('cancelsale', function(source, args)
    cancelHouseSale(source)
end, false)

-- Furniture commands
RegisterCommand('buyfurniture', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/buyfurniture [furniture_id]")
        return
    end
    
    local furnitureId = tonumber(args[1])
    if not furnitureId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid furniture ID.")
        return
    end
    
    buyFurniture(source, furnitureId)
end, false)

RegisterCommand('movefurniture', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/movefurniture [furniture_id]")
        return
    end
    
    local furnitureId = tonumber(args[1])
    if not furnitureId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid furniture ID.")
        return
    end
    
    moveFurniture(source, furnitureId)
end, false)

RegisterCommand('removefurniture', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/removefurniture [furniture_id]")
        return
    end
    
    local furnitureId = tonumber(args[1])
    if not furnitureId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid furniture ID.")
        return
    end
    
    removeFurniture(source, furnitureId)
end, false)

RegisterCommand('furniturecatalog', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    local category = args[1] or "all"
    
    local query = "SELECT * FROM furniture_catalog"
    local params = {}
    
    if category ~= "all" then
        query = query .. " WHERE Category = @category"
        params['@category'] = category
    end
    
    query = query .. " ORDER BY Category, Price"
    
    MySQL.query(query, params, function(furniture)
        if furniture and #furniture > 0 then
            TriggerClientEvent('chatMessage', source, "[FURNITURE CATALOG]", {0, 255, 255}, "=== Furniture Catalog ===")
            
            local currentCategory = ""
            for _, item in ipairs(furniture) do
                if item.Category ~= currentCategory then
                    currentCategory = item.Category
                    TriggerClientEvent('chatMessage', source, "[" .. currentCategory .. "]", {255, 255, 0}, "--- " .. currentCategory .. " ---")
                end
                
                local storageInfo = ""
                if item.IsStorage == 1 then
                    storageInfo = " (Storage: " .. item.StorageSlots .. " slots)"
                end
                
                TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 255, 255}, 
                    "ID: " .. item.ID .. " | " .. item.Name .. " | $" .. item.Price .. " | Level " .. item.Level .. storageInfo)
            end
        else
            TriggerClientEvent('chatMessage', source, "[FURNITURE]", {255, 0, 0}, "No furniture found.")
        end
    end)
end, false)

-- Court system commands
RegisterCommand('filecase', function(source, args)
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/filecase [defendant_id] [case_type] [description] [damages_amount]")
        TriggerClientEvent('chatMessage', source, "[INFO]", {255, 255, 255}, "Case types: Civil Lawsuit, Criminal Charges, Contract Dispute, Restraining Order")
        return
    end
    
    local defendantId = tonumber(args[1])
    if not defendantId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid defendant ID.")
        return
    end
    
    local caseType = args[2]
    local damagesAmount = tonumber(args[4]) or 0
    
    -- Remove first 3 arguments to get description
    table.remove(args, 1)
    table.remove(args, 1)
    if args[#args] and tonumber(args[#args]) then
        table.remove(args, #args) -- Remove damages amount if it exists
    end
    
    local description = table.concat(args, " ")
    
    if description == "" then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Description cannot be empty.")
        return
    end
    
    fileCourtCase(source, defendantId, caseType, description, damagesAmount)
end, false)

RegisterCommand('viewcase', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/viewcase [case_number]")
        return
    end
    
    local caseNumber = args[1]
    
    MySQL.query("SELECT * FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        local case = cases[1]
        
        -- Get participant names
        MySQL.query("SELECT ID, Name FROM characters WHERE ID IN (@plaintiff, @defendant, @lawyerP, @lawyerD, @judge)", {
            ['@plaintiff'] = case.PlaintiffID,
            ['@defendant'] = case.DefendantID,
            ['@lawyerP'] = case.LawyerPlaintiffID or 0,
            ['@lawyerD'] = case.LawyerDefendantID or 0,
            ['@judge'] = case.JudgeID or 0
        }, function(participants)
            local names = {}
            if participants then
                for _, participant in ipairs(participants) do
                    names[participant.ID] = participant.Name
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {0, 255, 255}, "=== Case " .. case.CaseNumber .. " ===")
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Type: " .. case.CaseType)
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Plaintiff: " .. (names[case.PlaintiffID] or "Unknown"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Defendant: " .. (names[case.DefendantID] or "Unknown"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Plaintiff's Lawyer: " .. (case.LawyerPlaintiffID and names[case.LawyerPlaintiffID] or "None"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Defendant's Lawyer: " .. (case.LawyerDefendantID and names[case.LawyerDefendantID] or "None"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Judge: " .. (case.JudgeID and names[case.JudgeID] or "Not Assigned"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Status: " .. case.Status)
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Filing Fee: $" .. case.FilingFee)
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Damages: $" .. case.Damages)
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Court Date: " .. (case.CourtDate or "Not Scheduled"))
            TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Description: " .. case.Description)
            if case.Verdict then
                TriggerClientEvent('chatMessage', source, "[CASE INFO]", {255, 255, 255}, "Verdict: " .. case.Verdict)
            end
        end)
    end)
end, false)

RegisterCommand('applylawyer', function(source, args)
    applyForLawyerLicense(source)
end, false)

RegisterCommand('hirelawyer', function(source, args)
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/hirelawyer [case_number] [lawyer_id] [side]")
        TriggerClientEvent('chatMessage', source, "[INFO]", {255, 255, 255}, "Side: plaintiff or defendant")
        return
    end
    
    local caseNumber = args[1]
    local lawyerId = tonumber(args[2])
    local side = string.lower(args[3])
    
    if not lawyerId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid lawyer ID.")
        return
    end
    
    if side ~= "plaintiff" and side ~= "defendant" then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Side must be 'plaintiff' or 'defendant'.")
        return
    end
    
    -- Find case by number
    MySQL.query("SELECT ID FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        hireLawyer(source, cases[1].ID, lawyerId, side)
    end)
end, false)

RegisterCommand('schedulecase', function(source, args)
    if #args < 4 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/schedulecase [case_number] [judge_id] [date] [time]")
        TriggerClientEvent('chatMessage', source, "[INFO]", {255, 255, 255}, "Date format: YYYY-MM-DD, Time format: HH:MM")
        return
    end
    
    local caseNumber = args[1]
    local judgeId = tonumber(args[2])
    local courtDate = args[3]
    local courtTime = args[4]
    
    if not judgeId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid judge ID.")
        return
    end
    
    -- Find case by number
    MySQL.query("SELECT ID FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        scheduleCourtHearing(source, cases[1].ID, judgeId, courtDate, courtTime)
    end)
end, false)

RegisterCommand('startcourt', function(source, args)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/startcourt [case_number]")
        return
    end
    
    local caseNumber = args[1]
    
    -- Find case by number
    MySQL.query("SELECT ID FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        startCourtSession(source, cases[1].ID)
    end)
end, false)

RegisterCommand('courtspeak', function(source, args)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/courtspeak [case_number] [statement]")
        return
    end
    
    local caseNumber = args[1]
    table.remove(args, 1)
    local statement = table.concat(args, " ")
    
    -- Find case by number
    MySQL.query("SELECT ID FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        makeCourtStatement(source, cases[1].ID, statement)
    end)
end, false)

RegisterCommand('closecase', function(source, args)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/closecase [case_number] [verdict] [damages]")
        return
    end
    
    local caseNumber = args[1]
    local damages = tonumber(args[#args])
    
    -- Remove case number and damages from args to get verdict
    table.remove(args, 1)
    if damages then
        table.remove(args, #args)
    else
        damages = 0
    end
    
    local verdict = table.concat(args, " ")
    
    -- Find case by number
    MySQL.query("SELECT ID FROM court_cases WHERE CaseNumber = @caseNumber", {
        ['@caseNumber'] = caseNumber
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
            return
        end
        
        closeCourtCase(source, cases[1].ID, verdict, damages)
    end)
end, false)

RegisterCommand('mycases', function(source, args)
    local player = PlayerData[source]
    if not player then return end
    
    MySQL.query("SELECT * FROM court_cases WHERE PlaintiffID = @charId OR DefendantID = @charId OR LawyerPlaintiffID = @charId OR LawyerDefendantID = @charId ORDER BY CreatedDate DESC", {
        ['@charId'] = player.CharacterID
    }, function(cases)
        if not cases or #cases == 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You have no court cases.")
            return
        end
        
        TriggerClientEvent('chatMessage', source, "[MY CASES]", {0, 255, 255}, "=== Your Court Cases ===")
        
        for _, case in ipairs(cases) do
            local role = "Unknown"
            if case.PlaintiffID == player.CharacterID then
                role = "Plaintiff"
            elseif case.DefendantID == player.CharacterID then
                role = "Defendant"
            elseif case.LawyerPlaintiffID == player.CharacterID then
                role = "Plaintiff's Lawyer"
            elseif case.LawyerDefendantID == player.CharacterID then
                role = "Defendant's Lawyer"
            end
            
            TriggerClientEvent('chatMessage', source, "[CASE]", {255, 255, 255}, 
                case.CaseNumber .. " | " .. case.CaseType .. " | " .. role .. " | " .. case.Status)
        end
    end)
end, false)

-- Admin housing commands
RegisterCommand('createhouse', function(source, args)
    local player = PlayerData[source]
    if not player or player.AdminLevel < 3 then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "You don't have permission to use this command.")
        return
    end
    
    if #args < 6 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/createhouse [x] [y] [z] [heading] [interior_id] [price] [name] [description]")
        return
    end
    
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    local heading = tonumber(args[4])
    local interiorId = tonumber(args[5])
    local price = tonumber(args[6])
    
    if not x or not y or not z or not heading or not interiorId or not price then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid coordinates, interior ID, or price.")
        return
    end
    
    -- Get name and description
    local name = args[7] or "New House"
    local description = args[8] or "A nice house"
    
    createHouse(x, y, z, heading, interiorId, price, name, description)
    TriggerClientEvent('chatMessage', source, "[ADMIN]", {0, 255, 0}, "House created successfully.")
end, false)

RegisterCommand('deletehouse', function(source, args)
    local player = PlayerData[source]
    if not player or player.AdminLevel < 3 then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "You don't have permission to use this command.")
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/deletehouse [house_id]")
        return
    end
    
    local houseId = tonumber(args[1])
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid house ID.")
        return
    end
    
    MySQL.query("DELETE FROM advanced_houses WHERE ID = @houseId", {
        ['@houseId'] = houseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Remove from local data
            AdvancedHouses[houseId] = nil
            FurnitureItems[houseId] = nil
            
            TriggerClientEvent('chatMessage', source, "[ADMIN]", {0, 255, 0}, "House deleted successfully.")
        else
            TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "House not found.")
        end
    end)
end, false)

RegisterCommand('gotohouse', function(source, args)
    local player = PlayerData[source]
    if not player or player.AdminLevel < 2 then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "You don't have permission to use this command.")
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[USAGE]", {255, 255, 0}, "/gotohouse [house_id]")
        return
    end
    
    local houseId = tonumber(args[1])
    if not houseId then
        TriggerClientEvent('chatMessage', source, "[ERROR]", {255, 0, 0}, "Invalid house ID.")
        return
    end
    
    local house = AdvancedHouses[houseId]
    if not house then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", {255, 0, 0}, "House not found.")
        return
    end
    
    SetEntityCoords(GetPlayerPed(source), house.ExteriorX, house.ExteriorY, house.ExteriorZ)
    TriggerClientEvent('chatMessage', source, "[ADMIN]", {0, 255, 0}, "Teleported to house ID " .. houseId .. ".")
end, false)

print("[SC:RP] Advanced housing and court commands loaded.")
