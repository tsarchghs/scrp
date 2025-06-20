-- Government system for SC:RP FiveM

Government = {
    mayor = 0, -- Character ID of the mayor
    treasury = 1000000, -- City treasury amount
    taxRate = 5, -- Tax rate percentage
    propertyTaxRate = 2, -- Property tax rate percentage
    businessTaxRate = 3, -- Business tax rate percentage
    incomeTaxRate = 4, -- Income tax rate percentage
    electionActive = false, -- Is an election currently active
    electionEndTime = 0, -- When the current election ends
    candidates = {} -- List of candidates for mayor
}

-- Initialize government tables
function initializeGovernmentTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `government` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Mayor` int(11) DEFAULT 0,
            `Treasury` int(11) DEFAULT 1000000,
            `TaxRate` int(2) DEFAULT 5,
            `PropertyTaxRate` int(2) DEFAULT 2,
            `BusinessTaxRate` int(2) DEFAULT 3,
            `IncomeTaxRate` int(2) DEFAULT 4,
            `LastTaxCollection` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `government_laws` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `Description` text NOT NULL,
            `CreatedBy` int(11) NOT NULL,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `government_elections` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `StartDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `EndDate` datetime NOT NULL,
            `Winner` int(11) DEFAULT NULL,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `government_candidates` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ElectionID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `Votes` int(11) DEFAULT 0,
            `Campaign` text DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ElectionID`) REFERENCES `government_elections`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `government_votes` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ElectionID` int(11) NOT NULL,
            `VoterID` int(11) NOT NULL,
            `CandidateID` int(11) NOT NULL,
            `VoteDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ElectionID`) REFERENCES `government_elections`(`ID`),
            FOREIGN KEY (`CandidateID`) REFERENCES `government_candidates`(`ID`),
            UNIQUE KEY `ElectionVoter` (`ElectionID`, `VoterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]], {})
end

-- Function to load government data
function loadGovernment()
    local query = [[
        SELECT * FROM `government` ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.Async.fetchAll(query, {}, function(rows)
        if #rows > 0 then
            local data = rows[1]
            Government.mayor = data.Mayor
            Government.treasury = data.Treasury
            Government.taxRate = data.TaxRate
            Government.propertyTaxRate = data.PropertyTaxRate
            Government.businessTaxRate = data.BusinessTaxRate
            Government.incomeTaxRate = data.IncomeTaxRate
        else
            -- Insert default government data
            MySQL.Async.execute([[
                INSERT INTO `government` (`Mayor`, `Treasury`, `TaxRate`, `PropertyTaxRate`, `BusinessTaxRate`, `IncomeTaxRate`)
                VALUES (0, 1000000, 5, 2, 3, 4)
            ]], {})
        end
        
        -- Load active election if any
        loadActiveElection()
    end)
end

-- Function to load active election
function loadActiveElection()
    local query = [[
        SELECT * FROM `government_elections` WHERE `Active` = 1 AND `EndDate` > NOW() ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.Async.fetchAll(query, {}, function(rows)
        if #rows > 0 then
            local election = rows[1]
            Government.electionActive = true
            Government.electionEndTime = os.time() + (os.difftime(os.time(election.EndDate), os.time()))
            
            -- Load candidates
            loadElectionCandidates(election.ID)
        else
            Government.electionActive = false
            Government.electionEndTime = 0
            Government.candidates = {}
        end
    end)
end

-- Function to load election candidates
function loadElectionCandidates(electionId)
    local query = [[
        SELECT gc.*, c.Name as CandidateName FROM `government_candidates` gc
        JOIN `characters` c ON gc.CharacterID = c.ID
        WHERE gc.`ElectionID` = @electionId
    ]]

    MySQL.Async.fetchAll(query, {
        ['@electionId'] = electionId
    }, function(rows)
        Government.candidates = {}
        for i = 1, #rows do
            local candidate = rows[i]
            table.insert(Government.candidates, {
                ID = candidate.ID,
                CharacterID = candidate.CharacterID,
                Name = candidate.CandidateName,
                Votes = candidate.Votes,
                Campaign = candidate.Campaign
            })
        end
    end)
end

-- Function to start an election
function startElection(duration)
    if Government.electionActive then
        return false, "An election is already active!"
    end
    
    local endDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + (duration * 86400)) -- duration in days
    
    local query = [[
        INSERT INTO `government_elections` (`EndDate`, `Active`)
        VALUES (@endDate, 1)
    ]]

    MySQL.Async.execute(query, {
        ['@endDate'] = endDate
    }, function(affectedRows)
        if affectedRows > 0 then
            local electionId = MySQL.insertId
            Government.electionActive = true
            Government.electionEndTime = os.time() + (duration * 86400)
            Government.candidates = {}
            
            -- Announce election
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 255, 0 }, 
                ("A mayoral election has started! It will end in %d days. Use /runformayor to become a candidate."):format(duration))
            
            -- Set timer to end election
            SetTimeout(duration * 86400 * 1000, function()
                endElection(electionId)
            end)
            
            return true, "Election started successfully!"
        end
        
        return false, "Failed to start election!"
    end)
end

-- Function to end an election
function endElection(electionId)
    local query = [[
        UPDATE `government_elections` SET `Active` = 0 WHERE `ID` = @electionId
    ]]

    MySQL.Async.execute(query, {
        ['@electionId'] = electionId
    })
    
    -- Find winner
    local query2 = [[
        SELECT gc.*, c.Name as CandidateName FROM `government_candidates` gc
        JOIN `characters` c ON gc.CharacterID = c.ID
        WHERE gc.`ElectionID` = @electionId
        ORDER BY gc.`Votes` DESC LIMIT 1
    ]]

    MySQL.Async.fetchAll(query2, {
        ['@electionId'] = electionId
    }, function(rows)
        if #rows > 0 then
            local winner = rows[1]
            
            -- Update election winner
            MySQL.Async.execute([[
                UPDATE `government_elections` SET `Winner` = @winnerId WHERE `ID` = @electionId
            ]], {
                ['@winnerId'] = winner.CharacterID,
                ['@electionId'] = electionId
            })
            
            -- Update government mayor
            MySQL.Async.execute([[
                UPDATE `government` SET `Mayor` = @mayor
            ]], {
                ['@mayor'] = winner.CharacterID
            })
            
            Government.mayor = winner.CharacterID
            
            -- Announce winner
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 0, 255, 0 }, 
                ("The election has ended! %s has been elected as the new mayor with %d votes!"):format(winner.CandidateName, winner.Votes))
        else
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 0, 0 }, 
                "The election has ended with no candidates!")
        end
        
        Government.electionActive = false
        Government.electionEndTime = 0
        Government.candidates = {}
    end)
end

-- Tax collection system
CreateThread(function()
    while true do
        Wait(86400000) -- 24 hours
        
        local totalTaxes = 0
        
        -- Update government treasury
        Government.treasury = Government.treasury + totalTaxes
        
        MySQL.Async.execute([[
            UPDATE `government` SET `Treasury` = @treasury, `LastTaxCollection` = NOW()
        ]], {
            ['@treasury'] = Government.treasury
        })
        
        if totalTaxes > 0 then
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 0, 255, 0 }, 
                ("Daily tax collection completed. $%d collected for the city treasury."):format(totalTaxes))
        end
    end
end)
