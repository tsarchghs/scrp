-- Business system commands

-- Create business command (admin only)
RegisterCommand('createbusiness', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 3) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args < 6 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, 
            "Usage: /createbusiness [type] [name] [price] [exitX] [exitY] [exitZ]")
        return
    end

    local businessType = tonumber(args[1])
    local name = args[2]
    local price = tonumber(args[3])
    local exitX = tonumber(args[4])
    local exitY = tonumber(args[5])
    local exitZ = tonumber(args[6])
    
    if not businessType or not price or not exitX or not exitY or not exitZ then return end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    createBusiness(businessType, name, coords.x, coords.y, coords.z, exitX, exitY, exitZ, 0, price)
    TriggerClientEvent('chatMessage', source, "[ADMIN]", { 0, 255, 0 }, 
        ("Business %s created"):format(name))
end, false)

-- Buy business command
RegisterCommand('buybusiness', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /buybusiness [business_id]")
        return
    end

    local businessId = tonumber(args[1])
    if not businessId then return end
    
    buyBusiness(source, businessId)
end, false)

-- Sell business command
RegisterCommand('sellbusiness', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /sellbusiness [business_id]")
        return
    end

    local businessId = tonumber(args[1])
    if not businessId then return end
    
    sellBusiness(source, businessId)
end, false)

-- Hire employee command
RegisterCommand('hire', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /hire [business_id] [player_id] [salary]")
        return
    end

    local businessId = tonumber(args[1])
    local targetId = tonumber(args[2])
    local salary = tonumber(args[3])
    
    if not businessId or not targetId or not salary then return end
    
    hireEmployee(source, businessId, targetId, salary)
end, false)

-- Fire employee command
RegisterCommand('fire', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /fire [business_id] [employee_id]")
        return
    end

    local businessId = tonumber(args[1])
    local employeeId = tonumber(args[2])
    
    if not businessId or not employeeId then return end
    
    fireEmployee(source, businessId, employeeId)
end, false)

-- Buy product command
RegisterCommand('buy', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /buy [business_id] [product_id] [quantity]")
        return
    end

    local businessId = tonumber(args[1])
    local productId = tonumber(args[2])
    local quantity = tonumber(args[3])
    
    if not businessId or not productId or not quantity then return end
    
    buyProduct(source, businessId, productId, quantity)
end, false)

-- Restock command
RegisterCommand('restock', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /restock [business_id] [product_id] [quantity]")
        return
    end

    local businessId = tonumber(args[1])
    local productId = tonumber(args[2])
    local quantity = tonumber(args[3])
    
    if not businessId or not productId or not quantity then return end
    
    restockProducts(source, businessId, productId, quantity)
end, false)

-- Withdraw from till command
RegisterCommand('withdraw', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /withdraw [business_id] [amount]")
        return
    end

    local businessId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not businessId or not amount then return end
    
    withdrawFromTill(source, businessId, amount)
end, false)

-- Deposit to till command
RegisterCommand('deposit', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[BUSINESS]", { 255, 0, 0 }, 
            "Usage: /deposit [business_id] [amount]")
        return
    end

    local businessId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not businessId or not amount then return end
    
    depositToTill(source, businessId, amount)
end, false)

-- List businesses command
RegisterCommand('businesses', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[BUSINESSES]", { 255, 255, 0 }, "Available Businesses:")
    
    for id, business in pairs(Businesses) do
        local owner = "For Sale"
        if business.OwnerID > 0 then
            owner = "Owned"
        end
        
        local businessTypeName = BusinessTypes[business.Type] and BusinessTypes[business.Type].name or "Unknown"
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s (%s) - %s - $%d"):format(id, business.Name, businessTypeName, owner, business.Price))
    end
end, false)

-- Skill commands
RegisterCommand('skills', function(source, args, rawCommand)
    if not PlayerData[source] or not PlayerSkills[source] then
        TriggerClientEvent('chatMessage', source, "[SKILLS]", { 255, 0, 0 }, "You are not logged in!")
        return
    end
    
    TriggerClientEvent('chatMessage', source, "[SKILLS]", { 255, 255, 0 }, "Your Skills:")
    
    for skillName, skillData in pairs(PlayerSkills[source]) do
        local xpNeeded = skillData.level * skillData.xpPerLevel
        local xpProgress = skillData.experience
        
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%s: Level %d (%d/%d XP)"):format(skillData.name, skillData.level, xpProgress, xpNeeded))
    end
end, false)

-- Craft command
RegisterCommand('craft', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[CRAFTING]", { 255, 0, 0 }, 
            "Usage: /craft [recipe_id]")
        return
    end

    local recipeId = args[1]
    craftItem(source, recipeId)
end, false)

-- List recipes command
RegisterCommand('recipes', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[CRAFTING]", { 255, 255, 0 }, "Available Recipes:")
    
    for recipeId, recipe in pairs(CraftingRecipes) do
        local skillReq = ""
        if recipe.skillRequired then
            skillReq = (" (Requires %s Level %d)"):format(Skills[recipe.skillRequired].name, recipe.skillLevel)
        end
        
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%s: %s%s"):format(recipeId, recipe.name, skillReq))
    end
end, false)

-- Government commands
RegisterCommand('startelection', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 4) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Usage: /startelection [duration_days]")
        return
    end

    local duration = tonumber(args[1])
    if not duration or duration < 1 or duration > 30 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Duration must be between 1 and 30 days!")
        return
    end
    
    local success, message = startElection(duration)
    local color = success and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", color, message)
end, false)

RegisterCommand('runformayor', function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Usage: /runformayor [campaign_message]")
        return
    end

    local campaign = table.concat(args, " ")
    local success, message = runForMayor(source, campaign)
    local color = success and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", color, message)
end, false)

RegisterCommand('vote', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Usage: /vote [candidate_id]")
        return
    end

    local candidateId = tonumber(args[1])
    if not candidateId then return end
    
    local success, message = voteForCandidate(source, candidateId)
    local color = success and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", color, message)
end, false)

RegisterCommand('candidates', function(source, args, rawCommand)
    if not Government.electionActive then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, "No active election!")
        return
    end
    
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, "Election Candidates:")
    
    for _, candidate in ipairs(Government.candidates) do
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s - %d votes - Campaign: %s"):format(candidate.ID, candidate.Name, candidate.Votes, candidate.Campaign or "No campaign message"))
    end
end, false)

RegisterCommand('settax', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Usage: /settax [type] [rate] (types: general, property, business, income)")
        return
    end

    local taxType = args[1]
    local rate = tonumber(args[2])
    
    if not rate then return end
    
    local success, message = setTaxRates(source, taxType, rate)
    local color = success and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", color, message)
end, false)

RegisterCommand('createlaw', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
            "Usage: /createlaw [name] [description]")
        return
    end

    local name = args[1]
    local description = table.concat(args, " ", 2)
    
    local success, message = createLaw(source, name, description)
    local color = success and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", color, message)
end, false)

RegisterCommand('treasury', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, 
        ("City Treasury: $%d"):format(Government.treasury))
    
    if Government.mayor > 0 then
        -- Find mayor name
        for targetSource, data in pairs(PlayerData) do
            if data.CharacterID == Government.mayor then
                TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, 
                    ("Current Mayor: %s"):format(data.Name))
                break
            end
        end
    else
        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, "No current mayor")
    end
    
    TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, 
        ("Tax Rates - General: %d%%, Property: %d%%, Business: %d%%, Income: %d%%"):format(
            Government.taxRate, Government.propertyTaxRate, Government.businessTaxRate, Government.incomeTaxRate))
end, false)
