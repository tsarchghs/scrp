-- Enhanced Commands for all new systems

-- Enhanced zone commands
RegisterCommand('captureturf', function(source, args, rawCommand)
    local playerZone = getPlayerZone(source)
    if not playerZone then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, "You are not in a zone!")
        return
    end
    
    enhancedStartZoneCapture(source, playerZone)
end, false)

RegisterCommand('zoneinfo', function(source, args, rawCommand)
    local playerZone = getPlayerZone(source)
    if not playerZone then
        TriggerClientEvent('chatMessage', source, "[ZONES]", { 255, 0, 0 }, "You are not in a zone!")
        return
    end
    
    local zone = EnhancedZones.zones[playerZone]
    local controllerName = "Unclaimed"
    if zone.controlledBy > 0 and Factions[zone.controlledBy] then
        controllerName = Factions[zone.controlledBy].Name
    end
    
    local zoneTypeName = EnhancedZones.zoneTypes[zone.type].name
    
    TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 255, 0 }, 
        ("Zone: %s (%s)"):format(zone.name, zoneTypeName))
    TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 255, 0 }, 
        ("Controlled by: %s"):format(controllerName))
    TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 255, 0 }, 
        ("Base Income: $%d/hour"):format(zone.baseIncome))
    TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 255, 0 }, 
        ("Required Members: %d"):format(zone.requiredMembers))
    
    if zone.isBeingCaptured then
        local contestingFactionName = Factions[zone.contestedBy] and Factions[zone.contestedBy].Name or "Unknown Faction"
        TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 0, 0 }, 
            ("Being captured by: %s (%.1f%%)"):format(contestingFactionName, zone.captureProgress))
    elseif zone.isProtected then
        local timeLeft = EnhancedZones.protectionTime - (os.time() - zone.protectionStartTime)
        if timeLeft > 0 then
            TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 0, 255, 0 }, 
                ("Protected for: %d seconds"):format(timeLeft))
        end
    end
    
    TriggerClientEvent('chatMessage', source, "[ZONE INFO]", { 255, 255, 0 }, "Activities:")
    for _, activity in ipairs(zone.activities) do
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("• %s"):format(activity:gsub("_", " ")))
    end
end, false)

RegisterCommand('zones', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[ENHANCED ZONES]", { 255, 255, 0 }, "Zone Control Status:")
    
    for zoneId, zone in pairs(EnhancedZones.zones) do
        local controllerName = "Unclaimed"
        local status = "Available"
        
        if zone.controlledBy > 0 and Factions[zone.controlledBy] then
            controllerName = Factions[zone.controlledBy].Name
            if zone.isProtected then
                local timeLeft = EnhancedZones.protectionTime - (os.time() - zone.protectionStartTime)
                if timeLeft > 0 then
                    status = ("Protected (%ds)"):format(timeLeft)
                else
                    status = "Vulnerable"
                end
            else
                status = "Vulnerable"
            end
        end
        
        if zone.isBeingCaptured then
            local contestingFactionName = Factions[zone.contestedBy] and Factions[zone.contestedBy].Name or "Unknown Faction"
            status = ("Being captured by %s"):format(contestingFactionName)
        end
        
        local zoneTypeName = EnhancedZones.zoneTypes[zone.type].name
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s (%s) - %s - %s - $%d/hr"):format(zoneId, zone.name, zoneTypeName, controllerName, status, zone.baseIncome))
    end
end, false)

-- Trucking commands
RegisterCommand('getlicense', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, 
            "Usage: /getlicense [type] (trucking)")
        return
    end

    local licenseType = args[1]
    if licenseType == "trucking" then
        getTruckingLicense(source)
    else
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "Invalid license type!")
    end
end, false)

RegisterCommand('startdelivery', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, 
            "Usage: /startdelivery [company_id] [route_id] [cargo_type]")
        return
    end

    local companyId = tonumber(args[1])
    local routeId = tonumber(args[2])
    local cargoType = args[3]
    
    if not companyId or not routeId then return end
    
    startDelivery(source, companyId, routeId, cargoType)
end, false)

RegisterCommand('deliveries', function(source, args, rawCommand)
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 255, 0 }, "Available Deliveries:")
    
    for companyId, company in pairs(TruckingSystem.companies) do
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s (Pay: %.1fx)"):format(companyId, company.name, company.payMultiplier))
    end
    
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 255, 0 }, "Available Routes:")
    for routeId, route in pairs(TruckingSystem.routes) do
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("%d. %s (%.1fkm, Difficulty: %d)"):format(routeId, route.name, route.distance, route.difficulty))
    end
    
    TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 255, 0 }, "Cargo Types:")
    for cargoType, cargo in pairs(TruckingSystem.cargoTypes) do
        local illegal = cargo.illegal and " (ILLEGAL)" or ""
        local fragile = cargo.fragile and " (FRAGILE)" or ""
        TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
            ("• %s - $%d%s%s"):format(cargo.name, cargo.value, illegal, fragile))
    end
end, false)

RegisterCommand('truckinginfo', function(source, args, rawCommand)
    if not PlayerData[source] or not TruckingSystem.driverData[source] then
        TriggerClientEvent('chatMessage', source, "[TRUCKING]", { 255, 0, 0 }, "Trucking data not loaded!")
        return
    end
    
    local data = TruckingSystem.driverData[source]
    TriggerClientEvent('chatMessage', source, "[TRUCKING INFO]", { 255, 255, 0 }, "Your Trucking Statistics:")
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("License: %s | Experience: %d"):format(data.license and "Yes" or "No", data.experience))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Reputation: %d | Deliveries: %d"):format(data.reputation, data.totalDeliveries))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Total Earnings: $%d"):format(data.totalEarnings))
end, false)

-- Casino commands
RegisterCommand('slots', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            "Usage: /slots [bet_amount]")
        return
    end

    local betAmount = tonumber(args[1])
    if not betAmount then return end
    
    playSlotMachine(source, betAmount)
end, false)

RegisterCommand('roulette', function(source, args, rawCommand)
    if #args ~= 3 then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            "Usage: /roulette [bet_type] [bet_value] [bet_amount]")
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 255, 0 }, 
            "Bet types: number, red, black, even, odd, low, high")
        return
    end

    local betType = args[1]
    local betValue = tonumber(args[2]) or args[2]
    local betAmount = tonumber(args[3])
    
    if not betAmount then return end
    
    playRoulette(source, betType, betValue, betAmount)
end, false)

RegisterCommand('blackjack', function(source, args, rawCommand)
    if #args ~= 1 then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            "Usage: /blackjack [bet_amount]")
        return
    end

    local betAmount = tonumber(args[1])
    if not betAmount then return end
    
    playBlackjack(source, betAmount)
end, false)

RegisterCommand('casinostats', function(source, args, rawCommand)
    if not PlayerData[source] or not CasinoSystem.playerStats[source] then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, "Casino data not loaded!")
        return
    end
    
    local stats = CasinoSystem.playerStats[source]
    TriggerClientEvent('chatMessage', source, "[CASINO STATS]", { 255, 255, 0 }, "Your Casino Statistics:")
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Games Played: %d | Total Wagered: $%d"):format(stats.gamesPlayed, stats.totalWagered))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Total Won: $%d | Total Lost: $%d"):format(stats.totalWon, stats.totalLost))
    TriggerClientEvent('chatMessage', source, "", { 200, 200, 200 }, 
        ("Biggest Win: $%d | VIP Status: %s"):format(stats.biggestWin, stats.vipStatus and "Yes" or "No"))
    
    local netResult = stats.totalWon - stats.totalLost
    local resultColor = netResult >= 0 and { 0, 255, 0 } or { 255, 0, 0 }
    TriggerClientEvent('chatMessage', source, "", resultColor, 
        ("Net Result: $%d"):format(netResult))
end, false)

-- Admin commands for new systems
RegisterCommand('createzone', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 4) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 255, 0 }, 
        "Zone creation requires manual database entry. Contact developer.")
end, false)

RegisterCommand('setcasinorevenue', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 5) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    -- Get today's casino revenue
    local query = [[
        SELECT SUM(`Profit`) as TotalProfit FROM `casino_revenue` WHERE `Date` = CURDATE()
    ]]

    MySQL.query(query, {}, function(rows)
        local profit = rows[1] and rows[1].TotalProfit or 0
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 0, 255, 0 }, 
            ("Today's casino profit: $%d"):format(profit))
    end)
end, false)

RegisterCommand('banplayer', function(source, args, rawCommand)
    if not isPlayerAdmin(source, 3) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have permission!")
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 255, 0, 0 }, 
            "Usage: /banplayer [player_id] [hours] [reason]")
        return
    end

    local targetId = tonumber(args[1])
    local hours = tonumber(args[2])
    local reason = table.concat(args, " ", 3)
    
    if not targetId or not hours then return end
    
    if PlayerData[targetId] then
        local banUntil = os.date("%Y-%m-%d %H:%M:%S", os.time() + (hours * 3600))
        
        MySQL.query([[
            UPDATE `casino_players` SET `BannedUntil` = @banUntil WHERE `CharacterID` = @characterId
        ]], {
            ['@banUntil'] = banUntil,
            ['@characterId'] = PlayerData[targetId].CharacterID
        })
        
        if CasinoSystem.playerStats[targetId] then
            CasinoSystem.playerStats[targetId].bannedUntil = banUntil
        end
        
        TriggerClientEvent('chatMessage', source, "[ADMIN]", { 0, 255, 0 }, 
            ("Banned %s from casino for %d hours"):format(PlayerData[targetId].Name, hours))
        TriggerClientEvent('chatMessage', targetId, "[CASINO]", { 255, 0, 0 }, 
            ("You have been banned from the casino for %d hours. Reason: %s"):format(hours, reason))
    end
end, false)
