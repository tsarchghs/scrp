-- Phone system

PhoneContacts = {}
PhoneMessages = {}

-- Initialize phone tables
function initializePhoneTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phone_contacts` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `ContactName` varchar(32) NOT NULL,
            `ContactNumber` varchar(16) NOT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phone_messages` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `SenderID` int(11) NOT NULL,
            `ReceiverNumber` varchar(16) NOT NULL,
            `Message` text NOT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            `Read` int(1) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phone_calls` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CallerID` int(11) NOT NULL,
            `ReceiverNumber` varchar(16) NOT NULL,
            `Duration` int(11) DEFAULT 0,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to send SMS
function sendSMS(source, targetNumber, message)
    if not PlayerData[source] then return false end
    
    local senderId = PlayerData[source].CharacterID
    local query = [[
        INSERT INTO `phone_messages` (`SenderID`, `ReceiverNumber`, `Message`)
        VALUES (@senderId, @targetNumber, @message)
    ]]

    MySQL.query(query, {
        ['@senderId'] = senderId,
        ['@targetNumber'] = targetNumber,
        ['@message'] = message
    }, function(rows, affected)
        if affected > 0 then
            -- Find receiver
            for targetSource, data in pairs(PlayerData) do
                if tostring(data.PhoneNumber) == targetNumber then
                    TriggerClientEvent('scrp:receiveMessage', targetSource, PlayerData[source].PhoneNumber, message)
                    break
                end
            end
            
            TriggerClientEvent('chatMessage', source, "[SMS]", { 0, 255, 0 }, 
                ("Message sent to %s"):format(targetNumber))
        end
    end)
end

-- Function to add contact
function addContact(source, contactName, contactNumber)
    if not PlayerData[source] then return false end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        INSERT INTO `phone_contacts` (`CharacterID`, `ContactName`, `ContactNumber`)
        VALUES (@characterId, @contactName, @contactNumber)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@contactName'] = contactName,
        ['@contactNumber'] = contactNumber
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', source, "[PHONE]", { 0, 255, 0 }, 
                ("Contact %s added"):format(contactName))
        end
    end)
end

-- Function to make phone call
function makePhoneCall(source, targetNumber)
    if not PlayerData[source] then return false end
    
    -- Find receiver
    local receiverSource = nil
    for targetSource, data in pairs(PlayerData) do
        if tostring(data.PhoneNumber) == targetNumber then
            receiverSource = targetSource
            break
        end
    end
    
    if receiverSource then
        TriggerClientEvent('scrp:incomingCall', receiverSource, PlayerData[source].PhoneNumber, PlayerData[source].Name)
        TriggerClientEvent('scrp:outgoingCall', source, targetNumber)
        
        -- Log call
        local query = [[
            INSERT INTO `phone_calls` (`CallerID`, `ReceiverNumber`)
            VALUES (@callerId, @receiverNumber)
        ]]
        
        MySQL.query(query, {
            ['@callerId'] = PlayerData[source].CharacterID,
            ['@receiverNumber'] = targetNumber
        })
    else
        TriggerClientEvent('chatMessage', source, "[PHONE]", { 255, 0, 0 }, "Number not available")
    end
end
