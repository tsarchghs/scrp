-- Court/Legal System for South Central Roleplay
-- Compatible with mysql-async 3.3.2 and FiveM artifact 15859
-- Author: SC:RP Development Team

-- Global variables
CourtCases = {}
LawyerLicenses = {}
JudgeSchedule = {}
CourtSessions = {}
LegalDocuments = {}

-- Initialize court system database tables
function initializeCourtTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `court_cases` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CaseNumber` varchar(32) NOT NULL UNIQUE,
            `PlaintiffID` int(11) NOT NULL,
            `DefendantID` int(11) NOT NULL,
            `LawyerPlaintiffID` int(11) DEFAULT NULL,
            `LawyerDefendantID` int(11) DEFAULT NULL,
            `JudgeID` int(11) DEFAULT NULL,
            `CaseType` varchar(64) NOT NULL,
            `Description` text NOT NULL,
            `Status` varchar(32) DEFAULT 'Pending',
            `FilingFee` int(11) DEFAULT 500,
            `CourtDate` datetime DEFAULT NULL,
            `Verdict` text DEFAULT NULL,
            `Damages` int(11) DEFAULT 0,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ClosedDate` datetime DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`PlaintiffID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`DefendantID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`LawyerPlaintiffID`) REFERENCES `characters`(`ID`) ON DELETE SET NULL,
            FOREIGN KEY (`LawyerDefendantID`) REFERENCES `characters`(`ID`) ON DELETE SET NULL,
            FOREIGN KEY (`JudgeID`) REFERENCES `characters`(`ID`) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `lawyer_licenses` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `LicenseNumber` varchar(32) NOT NULL UNIQUE,
            `Specialization` varchar(64) DEFAULT 'General Practice',
            `ExperienceLevel` int(2) DEFAULT 1,
            `CasesWon` int(11) DEFAULT 0,
            `CasesLost` int(11) DEFAULT 0,
            `LicenseStatus` varchar(32) DEFAULT 'Active',
            `IssuedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `ExpiryDate` datetime DEFAULT NULL,
            `BarExamScore` int(3) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `judge_schedule` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `JudgeID` int(11) NOT NULL,
            `CourtRoom` int(2) DEFAULT 1,
            `ScheduleDate` date NOT NULL,
            `StartTime` time NOT NULL,
            `EndTime` time NOT NULL,
            `CaseID` int(11) DEFAULT NULL,
            `Status` varchar(32) DEFAULT 'Available',
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`JudgeID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`CaseID`) REFERENCES `court_cases`(`ID`) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `legal_documents` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `DocumentType` varchar(64) NOT NULL,
            `Title` varchar(128) NOT NULL,
            `Content` text NOT NULL,
            `AuthorID` int(11) NOT NULL,
            `RelatedCaseID` int(11) DEFAULT NULL,
            `Status` varchar(32) DEFAULT 'Draft',
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `SignedDate` datetime DEFAULT NULL,
            `NotarizedBy` int(11) DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`AuthorID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`RelatedCaseID`) REFERENCES `court_cases`(`ID`) ON DELETE SET NULL,
            FOREIGN KEY (`NotarizedBy`) REFERENCES `characters`(`ID`) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `court_evidence` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CaseID` int(11) NOT NULL,
            `EvidenceType` varchar(64) NOT NULL,
            `Description` text NOT NULL,
            `SubmittedBy` int(11) NOT NULL,
            `EvidenceData` text DEFAULT NULL,
            `Status` varchar(32) DEFAULT 'Pending',
            `SubmittedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CaseID`) REFERENCES `court_cases`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`SubmittedBy`) REFERENCES `characters`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `court_transcripts` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CaseID` int(11) NOT NULL,
            `SessionDate` datetime NOT NULL,
            `SpeakerID` int(11) NOT NULL,
            `SpeakerRole` varchar(32) NOT NULL,
            `Statement` text NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CaseID`) REFERENCES `court_cases`(`ID`) ON DELETE CASCADE,
            FOREIGN KEY (`SpeakerID`) REFERENCES `characters`(`ID`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    print("[SC:RP] Court system tables initialized.")
    
    -- Initialize default case types and legal forms
    initializeLegalForms()
end

-- Initialize legal forms and case types
function initializeLegalForms()
    -- Check if legal forms are already initialized
    MySQL.Async.fetchAll("SELECT COUNT(*) as count FROM legal_documents WHERE DocumentType = 'Template'", {}, function(result)
        if result[1].count == 0 then
            -- Create default legal document templates
            local templates = {
                {
                    type = "Civil Lawsuit",
                    title = "Civil Lawsuit Filing Template",
                    content = "CIVIL LAWSUIT FILING\n\nPlaintiff: [PLAINTIFF_NAME]\nDefendant: [DEFENDANT_NAME]\n\nNature of Claim: [CLAIM_TYPE]\nDamages Sought: $[AMOUNT]\n\nStatement of Facts:\n[FACTS]\n\nLegal Basis:\n[LEGAL_BASIS]\n\nRelief Sought:\n[RELIEF]"
                },
                {
                    type = "Criminal Charges",
                    title = "Criminal Charges Filing Template",
                    content = "CRIMINAL CHARGES FILING\n\nDefendant: [DEFENDANT_NAME]\nCharges: [CHARGES]\n\nStatement of Facts:\n[FACTS]\n\nEvidence:\n[EVIDENCE]\n\nRecommended Sentence:\n[SENTENCE]"
                },
                {
                    type = "Contract",
                    title = "Legal Contract Template",
                    content = "LEGAL CONTRACT\n\nParty A: [PARTY_A]\nParty B: [PARTY_B]\n\nTerms and Conditions:\n[TERMS]\n\nPayment Terms:\n[PAYMENT]\n\nDuration: [DURATION]\n\nSignatures:\n[SIGNATURES]"
                },
                {
                    type = "Restraining Order",
                    title = "Restraining Order Template",
                    content = "RESTRAINING ORDER APPLICATION\n\nPetitioner: [PETITIONER]\nRespondent: [RESPONDENT]\n\nReason for Order:\n[REASON]\n\nIncidents:\n[INCIDENTS]\n\nRequested Restrictions:\n[RESTRICTIONS]"
                },
                {
                    type = "Subpoena",
                    title = "Subpoena Template",
                    content = "SUBPOENA\n\nTo: [RECIPIENT_NAME]\n\nYou are hereby commanded to appear in court on [DATE] at [TIME] in Courtroom [ROOM].\n\nCase: [CASE_NUMBER]\nPurpose: [PURPOSE]\n\nFailure to appear may result in contempt of court."
                }
            }
            
            for _, template in ipairs(templates) do
                MySQL.Async.execute("INSERT INTO legal_documents (DocumentType, Title, Content, AuthorID, Status) VALUES (@type, @title, @content, 0, 'Template')", {
                    ['@type'] = template.type,
                    ['@title'] = template.title,
                    ['@content'] = template.content
                })
            end
            
            print("[SC:RP] Legal document templates initialized.")
        end
    end)
end

-- File a new court case
function fileCourtCase(source, defendantId, caseType, description, damagesAmount)
    local player = PlayerData[source]
    if not player then return end
    
    local defendant = nil
    for src, data in pairs(PlayerData) do
        if data.CharacterID == defendantId then
            defendant = data
            break
        end
    end
    
    if not defendant then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Defendant not found.")
        return
    end
    
    -- Check filing fee
    local filingFee = 500
    if caseType == "Criminal Charges" then
        filingFee = 1000
    elseif caseType == "Civil Lawsuit" and damagesAmount > 50000 then
        filingFee = 1500
    end
    
    if player.Money < filingFee then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You need $" .. filingFee .. " to file this case.")
        return
    end
    
    -- Generate case number
    local caseNumber = "SC-" .. os.date("%Y") .. "-" .. string.format("%04d", math.random(1000, 9999))
    
    -- File the case
    MySQL.Async.execute("INSERT INTO court_cases (CaseNumber, PlaintiffID, DefendantID, CaseType, Description, FilingFee, Damages) VALUES (@caseNumber, @plaintiffId, @defendantId, @caseType, @description, @filingFee, @damages)", {
        ['@caseNumber'] = caseNumber,
        ['@plaintiffId'] = player.CharacterID,
        ['@defendantId'] = defendantId,
        ['@caseType'] = caseType,
        ['@description'] = description,
        ['@filingFee'] = filingFee,
        ['@damages'] = damagesAmount or 0
    }, function(result)
        if result.insertId then
            local caseId = result.insertId
            
            -- Deduct filing fee
            player.Money = player.Money - filingFee
            updatePlayerMoney(source)
            
            -- Add to local data
            CourtCases[caseId] = {
                ID = caseId,
                CaseNumber = caseNumber,
                PlaintiffID = player.CharacterID,
                DefendantID = defendantId,
                CaseType = caseType,
                Description = description,
                Status = "Pending",
                FilingFee = filingFee,
                Damages = damagesAmount or 0,
                CreatedDate = os.date("%Y-%m-%d %H:%M:%S")
            }
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Case filed successfully. Case Number: " .. caseNumber)
            
            -- Notify defendant
            for src, data in pairs(PlayerData) do
                if data.CharacterID == defendantId then
                    TriggerClientEvent('chatMessage', src, "[COURT]", {255, 165, 0}, "You have been named as defendant in case " .. caseNumber .. ". Type /viewcase " .. caseNumber .. " for details.")
                    break
                end
            end
            
            print(("[SC:RP] Court case %s filed by %s against %s"):format(caseNumber, player.Name, defendant.Name))
        end
    end)
end

-- Apply for lawyer license
function applyForLawyerLicense(source)
    local player = PlayerData[source]
    if not player then return end
    
    -- Check if player already has a license
    MySQL.Async.fetchAll("SELECT * FROM lawyer_licenses WHERE CharacterID = @charId", {
        ['@charId'] = player.CharacterID
    }, function(licenses)
        if licenses and #licenses > 0 then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You already have a lawyer license.")
            return
        end
        
        -- Check requirements
        local licenseFee = 10000
        if player.Money < licenseFee then
            TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You need $" .. licenseFee .. " to apply for a lawyer license.")
            return
        end
        
        -- Start bar exam
        TriggerClientEvent('scrp:startBarExam', source)
        
        TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Starting bar examination. Answer the questions correctly to obtain your license.")
    end)
end

-- Complete bar exam
function completeBarExam(source, score)
    local player = PlayerData[source]
    if not player then return end
    
    local passingScore = 70
    local licenseFee = 10000
    
    if score < passingScore then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You failed the bar exam with a score of " .. score .. "%. You need at least " .. passingScore .. "% to pass.")
        return
    end
    
    -- Deduct license fee
    player.Money = player.Money - licenseFee
    updatePlayerMoney(source)
    
    -- Generate license number
    local licenseNumber = "LAW-" .. string.format("%06d", math.random(100000, 999999))
    
    -- Issue license
    MySQL.Async.execute("INSERT INTO lawyer_licenses (CharacterID, LicenseNumber, BarExamScore, ExpiryDate) VALUES (@charId, @licenseNumber, @score, DATE_ADD(NOW(), INTERVAL 2 YEAR))", {
        ['@charId'] = player.CharacterID,
        ['@licenseNumber'] = licenseNumber,
        ['@score'] = score
    }, function(result)
        if result.insertId then
            LawyerLicenses[player.CharacterID] = {
                ID = result.insertId,
                CharacterID = player.CharacterID,
                LicenseNumber = licenseNumber,
                Specialization = "General Practice",
                ExperienceLevel = 1,
                CasesWon = 0,
                CasesLost = 0,
                LicenseStatus = "Active",
                BarExamScore = score
            }
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Congratulations! You passed the bar exam with " .. score .. "%. License Number: " .. licenseNumber)
            
            -- Add lawyer job
            player.Job = "Lawyer"
            player.JobRank = 1
            updatePlayerJob(source)
            
            print(("[SC:RP] %s obtained lawyer license %s with score %s%%"):format(player.Name, licenseNumber, score))
        end
    end)
end

-- Hire lawyer for case
function hireLawyer(source, caseId, lawyerId, side)
    local player = PlayerData[source]
    if not player then return end
    
    local case = CourtCases[caseId]
    if not case then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
        return
    end
    
    -- Check if player is involved in the case
    if case.PlaintiffID ~= player.CharacterID and case.DefendantID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You are not involved in this case.")
        return
    end
    
    -- Check if lawyer is licensed
    if not LawyerLicenses[lawyerId] then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "This person is not a licensed lawyer.")
        return
    end
    
    local lawyerFee = 5000 -- Base lawyer fee
    if player.Money < lawyerFee then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You need $" .. lawyerFee .. " to hire a lawyer.")
        return
    end
    
    -- Hire lawyer
    local columnName = side == "plaintiff" and "LawyerPlaintiffID" or "LawyerDefendantID"
    
    MySQL.Async.execute("UPDATE court_cases SET " .. columnName .. " = @lawyerId WHERE ID = @caseId", {
        ['@lawyerId'] = lawyerId,
        ['@caseId'] = caseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            if side == "plaintiff" then
                CourtCases[caseId].LawyerPlaintiffID = lawyerId
            else
                CourtCases[caseId].LawyerDefendantID = lawyerId
            end
            
            -- Deduct lawyer fee
            player.Money = player.Money - lawyerFee
            updatePlayerMoney(source)
            
            -- Pay lawyer
            for src, data in pairs(PlayerData) do
                if data.CharacterID == lawyerId then
                    data.Money = data.Money + lawyerFee
                    updatePlayerMoney(src)
                    TriggerClientEvent('chatMessage', src, "[COURT]", {0, 255, 0}, "You have been hired as a lawyer for case " .. case.CaseNumber .. ". Fee: $" .. lawyerFee)
                    break
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Lawyer hired successfully for case " .. case.CaseNumber .. ".")
        end
    end)
end

-- Schedule court hearing
function scheduleCourtHearing(source, caseId, judgeId, courtDate, courtTime)
    local player = PlayerData[source]
    if not player then return end
    
    -- Check if player is admin or judge
    if player.AdminLevel < 3 and player.Job ~= "Judge" then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Only judges and administrators can schedule court hearings.")
        return
    end
    
    local case = CourtCases[caseId]
    if not case then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
        return
    end
    
    if case.Status ~= "Pending" then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "This case is not pending.")
        return
    end
    
    -- Schedule the hearing
    local courtDateTime = courtDate .. " " .. courtTime .. ":00"
    
    MySQL.Async.execute("UPDATE court_cases SET JudgeID = @judgeId, CourtDate = @courtDate, Status = 'Scheduled' WHERE ID = @caseId", {
        ['@judgeId'] = judgeId,
        ['@courtDate'] = courtDateTime,
        ['@caseId'] = caseId
    }, function(result)
        if result.affectedRows > 0 then
            -- Update local data
            CourtCases[caseId].JudgeID = judgeId
            CourtCases[caseId].CourtDate = courtDateTime
            CourtCases[caseId].Status = "Scheduled"
            
            -- Notify all parties
            local parties = {case.PlaintiffID, case.DefendantID}
            if case.LawyerPlaintiffID then table.insert(parties, case.LawyerPlaintiffID) end
            if case.LawyerDefendantID then table.insert(parties, case.LawyerDefendantID) end
            
            for _, partyId in ipairs(parties) do
                for src, data in pairs(PlayerData) do
                    if data.CharacterID == partyId then
                        TriggerClientEvent('chatMessage', src, "[COURT]", {0, 255, 0}, "Court hearing scheduled for case " .. case.CaseNumber .. " on " .. courtDate .. " at " .. courtTime .. ".")
                        break
                    end
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Court hearing scheduled successfully.")
        end
    end)
end

-- Start court session
function startCourtSession(source, caseId)
    local player = PlayerData[source]
    if not player then return end
    
    local case = CourtCases[caseId]
    if not case then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
        return
    end
    
    -- Check if player is the assigned judge
    if case.JudgeID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You are not the assigned judge for this case.")
        return
    end
    
    if case.Status ~= "Scheduled" then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "This case is not scheduled for hearing.")
        return
    end
    
    -- Start the session
    MySQL.Async.execute("UPDATE court_cases SET Status = 'In Session' WHERE ID = @caseId", {
        ['@caseId'] = caseId
    }, function(result)
        if result.affectedRows > 0 then
            CourtCases[caseId].Status = "In Session"
            CourtSessions[caseId] = {
                JudgeID = player.CharacterID,
                StartTime = os.time(),
                Participants = {}
            }
            
            -- Notify all parties
            local parties = {case.PlaintiffID, case.DefendantID}
            if case.LawyerPlaintiffID then table.insert(parties, case.LawyerPlaintiffID) end
            if case.LawyerDefendantID then table.insert(parties, case.LawyerDefendantID) end
            
            for _, partyId in ipairs(parties) do
                for src, data in pairs(PlayerData) do
                    if data.CharacterID == partyId then
                        TriggerClientEvent('scrp:courtSessionStarted', src, caseId, case)
                        CourtSessions[caseId].Participants[src] = partyId
                        break
                    end
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Court session started for case " .. case.CaseNumber .. ".")
            
            -- Record transcript
            recordCourtTranscript(caseId, player.CharacterID, "Judge", "Court is now in session for case " .. case.CaseNumber .. ".")
        end
    end)
end

-- Record court transcript
function recordCourtTranscript(caseId, speakerId, role, statement)
    MySQL.Async.execute("INSERT INTO court_transcripts (CaseID, SessionDate, SpeakerID, SpeakerRole, Statement) VALUES (@caseId, NOW(), @speakerId, @role, @statement)", {
        ['@caseId'] = caseId,
        ['@speakerId'] = speakerId,
        ['@role'] = role,
        ['@statement'] = statement
    })
end

-- Make court statement
function makeCourtStatement(source, caseId, statement)
    local player = PlayerData[source]
    if not player then return end
    
    local session = CourtSessions[caseId]
    if not session then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "No active court session for this case.")
        return
    end
    
    if not session.Participants[source] then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You are not a participant in this court session.")
        return
    end
    
    local case = CourtCases[caseId]
    local role = "Unknown"
    
    if case.PlaintiffID == player.CharacterID then
        role = "Plaintiff"
    elseif case.DefendantID == player.CharacterID then
        role = "Defendant"
    elseif case.LawyerPlaintiffID == player.CharacterID then
        role = "Plaintiff's Attorney"
    elseif case.LawyerDefendantID == player.CharacterID then
        role = "Defendant's Attorney"
    elseif case.JudgeID == player.CharacterID then
        role = "Judge"
    end
    
    -- Record transcript
    recordCourtTranscript(caseId, player.CharacterID, role, statement)
    
    -- Broadcast to all participants
    for participantSource, _ in pairs(session.Participants) do
        TriggerClientEvent('scrp:courtStatement', participantSource, player.Name, role, statement)
    end
    
    print(("[SC:RP] Court statement in case %s by %s (%s): %s"):format(case.CaseNumber, player.Name, role, statement))
end

-- Close court case with verdict
function closeCourtCase(source, caseId, verdict, damages)
    local player = PlayerData[source]
    if not player then return end
    
    local case = CourtCases[caseId]
    if not case then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "Case not found.")
        return
    end
    
    -- Check if player is the assigned judge
    if case.JudgeID ~= player.CharacterID then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "You are not the assigned judge for this case.")
        return
    end
    
    if case.Status ~= "In Session" then
        TriggerClientEvent('chatMessage', source, "[COURT]", {255, 0, 0}, "This case is not in session.")
        return
    end
    
    -- Close the case
    MySQL.Async.execute("UPDATE court_cases SET Status = 'Closed', Verdict = @verdict, Damages = @damages, ClosedDate = NOW() WHERE ID = @caseId", {
        ['@caseId'] = caseId,
        ['@verdict'] = verdict,
        ['@damages'] = damages or 0
    }, function(result)
        if result.affectedRows > 0 then
            CourtCases[caseId].Status = "Closed"
            CourtCases[caseId].Verdict = verdict
            CourtCases[caseId].Damages = damages or 0
            
            -- Record final transcript
            recordCourtTranscript(caseId, player.CharacterID, "Judge", "VERDICT: " .. verdict .. ". Damages awarded: $" .. (damages or 0))
            
            -- Handle damages payment
            if damages and damages > 0 then
                -- Find defendant and plaintiff
                for src, data in pairs(PlayerData) do
                    if data.CharacterID == case.DefendantID then
                        if data.Money >= damages then
                            data.Money = data.Money - damages
                            updatePlayerMoney(src)
                            TriggerClientEvent('chatMessage', src, "[COURT]", {255, 0, 0}, "You have been ordered to pay $" .. damages .. " in damages.")
                        else
                            TriggerClientEvent('chatMessage', src, "[COURT]", {255, 0, 0}, "You owe $" .. damages .. " in court-ordered damages but don't have enough money.")
                        end
                        break
                    end
                end
                
                for src, data in pairs(PlayerData) do
                    if data.CharacterID == case.PlaintiffID then
                        data.Money = data.Money + damages
                        updatePlayerMoney(src)
                        TriggerClientEvent('chatMessage', src, "[COURT]", {0, 255, 0}, "You have been awarded $" .. damages .. " in damages.")
                        break
                    end
                end
            end
            
            -- Update lawyer statistics
            if case.LawyerPlaintiffID and LawyerLicenses[case.LawyerPlaintiffID] then
                if string.find(string.lower(verdict), "plaintiff") then
                    LawyerLicenses[case.LawyerPlaintiffID].CasesWon = LawyerLicenses[case.LawyerPlaintiffID].CasesWon + 1
                else
                    LawyerLicenses[case.LawyerPlaintiffID].CasesLost = LawyerLicenses[case.LawyerPlaintiffID].CasesLost + 1
                end
                
                MySQL.Async.execute("UPDATE lawyer_licenses SET CasesWon = @won, CasesLost = @lost WHERE CharacterID = @charId", {
                    ['@won'] = LawyerLicenses[case.LawyerPlaintiffID].CasesWon,
                    ['@lost'] = LawyerLicenses[case.LawyerPlaintiffID].CasesLost,
                    ['@charId'] = case.LawyerPlaintiffID
                })
            end
            
            if case.LawyerDefendantID and LawyerLicenses[case.LawyerDefendantID] then
                if string.find(string.lower(verdict), "defendant") then
                    LawyerLicenses[case.LawyerDefendantID].CasesWon = LawyerLicenses[case.LawyerDefendantID].CasesWon + 1
                else
                    LawyerLicenses[case.LawyerDefendantID].CasesLost = LawyerLicenses[case.LawyerDefendantID].CasesLost + 1
                end
                
                MySQL.Async.execute("UPDATE lawyer_licenses SET CasesWon = @won, CasesLost = @lost WHERE CharacterID = @charId", {
                    ['@won'] = LawyerLicenses[case.LawyerDefendantID].CasesWon,
                    ['@lost'] = LawyerLicenses[case.LawyerDefendantID].CasesLost,
                    ['@charId'] = case.LawyerDefendantID
                })
            end
            
            -- Notify all parties
            local session = CourtSessions[caseId]
            if session then
                for participantSource, _ in pairs(session.Participants) do
                    TriggerClientEvent('scrp:courtCaseClosed', participantSource, case.CaseNumber, verdict, damages or 0)
                end
                CourtSessions[caseId] = nil
            end
            
            TriggerClientEvent('chatMessage', source, "[COURT]", {0, 255, 0}, "Case " .. case.CaseNumber .. " closed successfully.")
        end
    end)
end

-- Load court system data
function loadCourtSystem()
    -- Load court cases
    MySQL.Async.fetchAll("SELECT * FROM court_cases WHERE Status != 'Closed'", {}, function(cases)
        if cases then
            for _, case in ipairs(cases) do
                CourtCases[case.ID] = case
            end
            print(("[SC:RP] Loaded %s active court cases."):format(#cases))
        end
    end)
    
    -- Load lawyer licenses
    MySQL.Async.fetchAll("SELECT * FROM lawyer_licenses WHERE LicenseStatus = 'Active'", {}, function(licenses)
        if licenses then
            for _, license in ipairs(licenses) do
                LawyerLicenses[license.CharacterID] = license
            end
            print(("[SC:RP] Loaded %s active lawyer licenses."):format(#licenses))
        end
    end)
end

-- Initialize court system
function initializeCourtSystem()
    initializeCourtTables()
    loadCourtSystem()
    print("[SC:RP] Court system initialized.")
end

-- Event handlers
RegisterServerEvent('scrp:fileCourtCase')
AddEventHandler('scrp:fileCourtCase', function(defendantId, caseType, description, damagesAmount)
    fileCourtCase(source, defendantId, caseType, description, damagesAmount)
end)

RegisterServerEvent('scrp:applyForLawyerLicense')
AddEventHandler('scrp:applyForLawyerLicense', function()
    applyForLawyerLicense(source)
end)

RegisterServerEvent('scrp:completeBarExam')
AddEventHandler('scrp:completeBarExam', function(score)
    completeBarExam(source, score)
end)

RegisterServerEvent('scrp:hireLawyer')
AddEventHandler('scrp:hireLawyer', function(caseId, lawyerId, side)
    hireLawyer(source, caseId, lawyerId, side)
end)

RegisterServerEvent('scrp:scheduleCourtHearing')
AddEventHandler('scrp:scheduleCourtHearing', function(caseId, judgeId, courtDate, courtTime)
    scheduleCourtHearing(source, caseId, judgeId, courtDate, courtTime)
end)

RegisterServerEvent('scrp:startCourtSession')
AddEventHandler('scrp:startCourtSession', function(caseId)
    startCourtSession(source, caseId)
end)

RegisterServerEvent('scrp:makeCourtStatement')
AddEventHandler('scrp:makeCourtStatement', function(caseId, statement)
    makeCourtStatement(source, caseId, statement)
end)

RegisterServerEvent('scrp:closeCourtCase')
AddEventHandler('scrp:closeCourtCase', function(caseId, verdict, damages)
    closeCourtCase(source, caseId, verdict, damages)
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initializeCourtSystem()
    end
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    -- Remove player from any active court sessions
    for caseId, session in pairs(CourtSessions) do
        if session.Participants[source] then
            session.Participants[source] = nil
        end
    end
end)
