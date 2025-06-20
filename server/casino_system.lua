-- Advanced Casino/Gambling System for SC:RP FiveM

CasinoSystem = {
    location = {x = 1100.0, y = 220.0, z = -49.0}, -- Diamond Casino
    
    games = {
        ["blackjack"] = {
            name = "Blackjack",
            minBet = 100,
            maxBet = 10000,
            tables = {},
            houseEdge = 0.05
        },
        ["poker"] = {
            name = "Poker",
            minBet = 500,
            maxBet = 50000,
            tables = {},
            houseEdge = 0.03
        },
        ["roulette"] = {
            name = "Roulette",
            minBet = 50,
            maxBet = 25000,
            tables = {},
            houseEdge = 0.027
        },
        ["slots"] = {
            name = "Slot Machines",
            minBet = 10,
            maxBet = 1000,
            machines = {},
            houseEdge = 0.08
        }
    },
    
    activeTables = {},
    playerStats = {},
    casinoRevenue = 0
}

-- Initialize casino tables
function initializeCasinoTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `casino_players` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `TotalWagered` int(11) DEFAULT 0,
            `TotalWon` int(11) DEFAULT 0,
            `TotalLost` int(11) DEFAULT 0,
            `GamesPlayed` int(11) DEFAULT 0,
            `BiggestWin` int(11) DEFAULT 0,
            `VIPStatus` int(1) DEFAULT 0,
            `BannedUntil` datetime DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`),
            UNIQUE KEY `CharacterID` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `casino_games` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `PlayerID` int(11) NOT NULL,
            `GameType` varchar(16) NOT NULL,
            `BetAmount` int(11) NOT NULL,
            `WinAmount` int(11) DEFAULT 0,
            `GameData` text DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `casino_revenue` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Date` date NOT NULL,
            `GameType` varchar(16) NOT NULL,
            `TotalWagered` int(11) DEFAULT 0,
            `TotalPaid` int(11) DEFAULT 0,
            `Profit` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`),
            UNIQUE KEY `DateGame` (`Date`, `GameType`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Load player casino stats
function loadCasinoStats(source, characterId)
    local query = [[
        SELECT * FROM `casino_players` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local data = rows[1]
            CasinoSystem.playerStats[source] = {
                totalWagered = data.TotalWagered,
                totalWon = data.TotalWon,
                totalLost = data.TotalLost,
                gamesPlayed = data.GamesPlayed,
                biggestWin = data.BiggestWin,
                vipStatus = data.VIPStatus == 1,
                bannedUntil = data.BannedUntil
            }
        else
            -- Create new casino player record
            MySQL.query([[
                INSERT INTO `casino_players` (`CharacterID`) VALUES (@characterId)
            ]], {
                ['@characterId'] = characterId
            })
            
            CasinoSystem.playerStats[source] = {
                totalWagered = 0,
                totalWon = 0,
                totalLost = 0,
                gamesPlayed = 0,
                biggestWin = 0,
                vipStatus = false,
                bannedUntil = nil
            }
        end
    end)
end

-- Play slot machine
function playSlotMachine(source, betAmount)
    if not PlayerData[source] or not CasinoSystem.playerStats[source] then return false end
    
    local game = CasinoSystem.games["slots"]
    
    -- Validate bet
    if betAmount < game.minBet or betAmount > game.maxBet then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Bet must be between $%d and $%d"):format(game.minBet, game.maxBet))
        return false
    end
    
    if PlayerData[source].Money < betAmount then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, "Insufficient funds!")
        return false
    end
    
    -- Check if banned
    if CasinoSystem.playerStats[source].bannedUntil then
        local banTime = os.time(CasinoSystem.playerStats[source].bannedUntil)
        if os.time() < banTime then
            TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, "You are banned from the casino!")
            return false
        end
    end
    
    -- Deduct bet
    PlayerData[source].Money = PlayerData[source].Money - betAmount
    
    -- Generate slot results
    local symbols = {"🍒", "🍋", "🍊", "🔔", "⭐", "💎", "7️⃣"}
    local weights = {30, 25, 20, 15, 7, 2, 1} -- Probability weights
    
    local reels = {}
    for i = 1, 3 do
        reels[i] = getWeightedRandomSymbol(symbols, weights)
    end
    
    -- Calculate winnings
    local winAmount = calculateSlotWinnings(reels, betAmount)
    
    if winAmount > 0 then
        PlayerData[source].Money = PlayerData[source].Money + winAmount
        CasinoSystem.playerStats[source].totalWon = CasinoSystem.playerStats[source].totalWon + winAmount
        
        if winAmount > CasinoSystem.playerStats[source].biggestWin then
            CasinoSystem.playerStats[source].biggestWin = winAmount
        end
        
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 0, 255, 0 }, 
            ("Slots: %s | %s | %s - You won $%d!"):format(reels[1], reels[2], reels[3], winAmount))
    else
        CasinoSystem.playerStats[source].totalLost = CasinoSystem.playerStats[source].totalLost + betAmount
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Slots: %s | %s | %s - You lost $%d"):format(reels[1], reels[2], reels[3], betAmount))
    end
    
    -- Update stats
    CasinoSystem.playerStats[source].totalWagered = CasinoSystem.playerStats[source].totalWagered + betAmount
    CasinoSystem.playerStats[source].gamesPlayed = CasinoSystem.playerStats[source].gamesPlayed + 1
    
    -- Log game
    logCasinoGame(source, "slots", betAmount, winAmount, json.encode({reels = reels}))
    
    -- Update casino revenue
    updateCasinoRevenue("slots", betAmount, winAmount)
    
    -- Save stats
    saveCasinoStats(source)
    
    return true
end

-- Calculate slot winnings
function calculateSlotWinnings(reels, betAmount)
    -- Three of a kind
    if reels[1] == reels[2] and reels[2] == reels[3] then
        local multipliers = {
            ["🍒"] = 5,
            ["🍋"] = 8,
            ["🍊"] = 10,
            ["🔔"] = 15,
            ["⭐"] = 25,
            ["💎"] = 50,
            ["7️⃣"] = 100
        }
        return betAmount * (multipliers[reels[1]] or 5)
    end
    
    -- Two of a kind
    if reels[1] == reels[2] or reels[2] == reels[3] or reels[1] == reels[3] then
        return betAmount * 2
    end
    
    -- Special combinations
    if (reels[1] == "🍒" or reels[2] == "🍒" or reels[3] == "🍒") then
        return betAmount -- Cherry pays even with one
    end
    
    return 0
end

-- Get weighted random symbol
function getWeightedRandomSymbol(symbols, weights)
    local totalWeight = 0
    for _, weight in ipairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for i, weight in ipairs(weights) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return symbols[i]
        end
    end
    
    return symbols[1]
end

-- Play roulette
function playRoulette(source, betType, betValue, betAmount)
    if not PlayerData[source] or not CasinoSystem.playerStats[source] then return false end
    
    local game = CasinoSystem.games["roulette"]
    
    -- Validate bet
    if betAmount < game.minBet or betAmount > game.maxBet then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Bet must be between $%d and $%d"):format(game.minBet, game.maxBet))
        return false
    end
    
    if PlayerData[source].Money < betAmount then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, "Insufficient funds!")
        return false
    end
    
    -- Deduct bet
    PlayerData[source].Money = PlayerData[source].Money - betAmount
    
    -- Spin the wheel (0-36, with 0 being green)
    local result = math.random(0, 36)
    local isRed = isRedNumber(result)
    local isEven = result > 0 and result % 2 == 0
    
    -- Calculate winnings based on bet type
    local winAmount = 0
    local won = false
    
    if betType == "number" and betValue == result then
        winAmount = betAmount * 35 -- 35:1 payout
        won = true
    elseif betType == "red" and isRed and result > 0 then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    elseif betType == "black" and not isRed and result > 0 then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    elseif betType == "even" and isEven then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    elseif betType == "odd" and not isEven and result > 0 then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    elseif betType == "low" and result >= 1 and result <= 18 then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    elseif betType == "high" and result >= 19 and result <= 36 then
        winAmount = betAmount * 2 -- 1:1 payout
        won = true
    end
    
    if won then
        PlayerData[source].Money = PlayerData[source].Money + winAmount
        CasinoSystem.playerStats[source].totalWon = CasinoSystem.playerStats[source].totalWon + winAmount
        
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 0, 255, 0 }, 
            ("Roulette: %d (%s) - You won $%d!"):format(result, getRouletteColor(result), winAmount))
    else
        CasinoSystem.playerStats[source].totalLost = CasinoSystem.playerStats[source].totalLost + betAmount
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Roulette: %d (%s) - You lost $%d"):format(result, getRouletteColor(result), betAmount))
    end
    
    -- Update stats
    CasinoSystem.playerStats[source].totalWagered = CasinoSystem.playerStats[source].totalWagered + betAmount
    CasinoSystem.playerStats[source].gamesPlayed = CasinoSystem.playerStats[source].gamesPlayed + 1
    
    -- Log game
    logCasinoGame(source, "roulette", betAmount, winAmount, json.encode({
        result = result,
        betType = betType,
        betValue = betValue
    }))
    
    -- Update casino revenue
    updateCasinoRevenue("roulette", betAmount, winAmount)
    
    -- Save stats
    saveCasinoStats(source)
    
    return true
end

-- Check if roulette number is red
function isRedNumber(number)
    local redNumbers = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
    for _, red in ipairs(redNumbers) do
        if number == red then
            return true
        end
    end
    return false
end

-- Get roulette color name
function getRouletteColor(number)
    if number == 0 then
        return "Green"
    elseif isRedNumber(number) then
        return "Red"
    else
        return "Black"
    end
end

-- Simple blackjack game
function playBlackjack(source, betAmount)
    if not PlayerData[source] or not CasinoSystem.playerStats[source] then return false end
    
    local game = CasinoSystem.games["blackjack"]
    
    -- Validate bet
    if betAmount < game.minBet or betAmount > game.maxBet then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Bet must be between $%d and $%d"):format(game.minBet, game.maxBet))
        return false
    end
    
    if PlayerData[source].Money < betAmount then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, "Insufficient funds!")
        return false
    end
    
    -- Deduct bet
    PlayerData[source].Money = PlayerData[source].Money - betAmount
    
    -- Create deck and deal cards
    local deck = createDeck()
    shuffleDeck(deck)
    
    local playerHand = {deck[1], deck[2]}
    local dealerHand = {deck[3], deck[4]}
    local deckIndex = 5
    
    local playerValue = calculateHandValue(playerHand)
    local dealerValue = calculateHandValue(dealerHand)
    
    -- Check for natural blackjack
    local winAmount = 0
    if playerValue == 21 and dealerValue ~= 21 then
        winAmount = math.floor(betAmount * 2.5) -- 3:2 payout for blackjack
        PlayerData[source].Money = PlayerData[source].Money + winAmount
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 0, 255, 0 }, 
            ("Blackjack! You won $%d"):format(winAmount))
    elseif dealerValue == 21 and playerValue ~= 21 then
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
            ("Dealer blackjack! You lost $%d"):format(betAmount))
    elseif playerValue == 21 and dealerValue == 21 then
        PlayerData[source].Money = PlayerData[source].Money + betAmount -- Push
        TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 255, 0 }, 
            "Push! Both have blackjack")
    else
        -- Simplified AI dealer play
        while dealerValue < 17 do
            table.insert(dealerHand, deck[deckIndex])
            deckIndex = deckIndex + 1
            dealerValue = calculateHandValue(dealerHand)
        end
        
        -- Determine winner
        if dealerValue > 21 then
            winAmount = betAmount * 2
            PlayerData[source].Money = PlayerData[source].Money + winAmount
            TriggerClientEvent('chatMessage', source, "[CASINO]", { 0, 255, 0 }, 
                ("Dealer busts! You won $%d"):format(winAmount))
        elseif playerValue > dealerValue then
            winAmount = betAmount * 2
            PlayerData[source].Money = PlayerData[source].Money + winAmount
            TriggerClientEvent('chatMessage', source, "[CASINO]", { 0, 255, 0 }, 
                ("You won! (%d vs %d) $%d"):format(playerValue, dealerValue, winAmount))
        elseif dealerValue > playerValue then
            TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 0, 0 }, 
                ("Dealer wins! (%d vs %d) You lost $%d"):format(dealerValue, playerValue, betAmount))
        else
            PlayerData[source].Money = PlayerData[source].Money + betAmount -- Push
            TriggerClientEvent('chatMessage', source, "[CASINO]", { 255, 255, 0 }, 
                ("Push! (%d vs %d)"):format(playerValue, dealerValue))
        end
    end
    
    -- Update stats and log
    CasinoSystem.playerStats[source].totalWagered = CasinoSystem.playerStats[source].totalWagered + betAmount
    CasinoSystem.playerStats[source].gamesPlayed = CasinoSystem.playerStats[source].gamesPlayed + 1
    
    if winAmount > 0 then
        CasinoSystem.playerStats[source].totalWon = CasinoSystem.playerStats[source].totalWon + winAmount
    else
        CasinoSystem.playerStats[source].totalLost = CasinoSystem.playerStats[source].totalLost + betAmount
    end
    
    logCasinoGame(source, "blackjack", betAmount, winAmount, json.encode({
        playerHand = playerHand,
        dealerHand = dealerHand,
        playerValue = playerValue,
        dealerValue = dealerValue
    }))
    
    updateCasinoRevenue("blackjack", betAmount, winAmount)
    saveCasinoStats(source)
    
    return true
end

-- Create standard deck of cards
function createDeck()
    local suits = {"♠", "♥", "♦", "♣"}
    local ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
    local deck = {}
    
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            table.insert(deck, {suit = suit, rank = rank})
        end
    end
    
    return deck
end

-- Shuffle deck
function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Calculate blackjack hand value
function calculateHandValue(hand)
    local value = 0
    local aces = 0
    
    for _, card in ipairs(hand) do
        if card.rank == "A" then
            aces = aces + 1
            value = value + 11
        elseif card.rank == "K" or card.rank == "Q" or card.rank == "J" then
            value = value + 10
        else
            value = value + tonumber(card.rank)
        end
    end
    
    -- Handle aces
    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end
    
    return value
end

-- Log casino game
function logCasinoGame(source, gameType, betAmount, winAmount, gameData)
    MySQL.query([[
        INSERT INTO `casino_games` (`PlayerID`, `GameType`, `BetAmount`, `WinAmount`, `GameData`)
        VALUES (@playerId, @gameType, @betAmount, @winAmount, @gameData)
    ]], {
        ['@playerId'] = PlayerData[source].CharacterID,
        ['@gameType'] = gameType,
        ['@betAmount'] = betAmount,
        ['@winAmount'] = winAmount,
        ['@gameData'] = gameData
    })
end

-- Update casino revenue
function updateCasinoRevenue(gameType, wagered, paid)
    local today = os.date("%Y-%m-%d")
    local profit = wagered - paid
    
    MySQL.query([[
        INSERT INTO `casino_revenue` (`Date`, `GameType`, `TotalWagered`, `TotalPaid`, `Profit`)
        VALUES (@date, @gameType, @wagered, @paid, @profit)
        ON DUPLICATE KEY UPDATE 
        `TotalWagered` = `TotalWagered` + @wagered,
        `TotalPaid` = `TotalPaid` + @paid,
        `Profit` = `Profit` + @profit
    ]], {
        ['@date'] = today,
        ['@gameType'] = gameType,
        ['@wagered'] = wagered,
        ['@paid'] = paid,
        ['@profit'] = profit
    })
end

-- Save casino stats
function saveCasinoStats(source)
    if not PlayerData[source] or not CasinoSystem.playerStats[source] then return end
    
    local characterId = PlayerData[source].CharacterID
    local stats = CasinoSystem.playerStats[source]
    
    MySQL.query([[
        UPDATE `casino_players` SET 
        `TotalWagered` = @wagered, `TotalWon` = @won, `TotalLost` = @lost,
        `GamesPlayed` = @games, `BiggestWin` = @biggestWin
        WHERE `CharacterID` = @characterId
    ]], {
        ['@wagered'] = stats.totalWagered,
        ['@won'] = stats.totalWon,
        ['@lost'] = stats.totalLost,
        ['@games'] = stats.gamesPlayed,
        ['@biggestWin'] = stats.biggestWin,
        ['@characterId'] = characterId
    })
end
