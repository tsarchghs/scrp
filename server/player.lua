-- Player data management

PlayerData = {}

-- Function to load player character data
function loadPlayerData(source, characterId)
    local query = [[
        SELECT * FROM `characters` WHERE `ID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if #rows > 0 then
            local data = rows[1]
            PlayerData[source] = {
                CharacterID = data.ID,
                AccountID = data.AccountID,
                Name = data.Name,
                Age = data.Age,
                Gender = data.Gender,
                Skin = data.Skin,
                Money = data.Money,
                BankMoney = data.BankMoney,
                Position = {x = data.PosX, y = data.PosY, z = data.PosZ, heading = data.PosA},
                Health = data.Health,
                Armour = data.Armour,
                FactionID = data.FactionID,
                FactionRank = data.FactionRank,
                JobID = data.JobID,
                Level = data.Level,
                Exp = data.Exp,
                PlayingHours = data.PlayingHours,
                PhoneNumber = data.PhoneNumber,
                Jailed = data.Jailed,
                JailTime = data.JailTime,
                Inventory = {}
            }

            -- Load inventory
            loadPlayerInventory(source, characterId)
            
            -- Set player position and model
            TriggerClientEvent('scrp:setPlayerData', source, PlayerData[source])
            
            print(("[SC:RP] Loaded character data for %s"):format(data.Name))
        end
    end)
end

-- Function to save player data
function savePlayerData(source)
    if not PlayerData[source] then return end
    
    local data = PlayerData[source]
    local query = [[
        UPDATE `characters` SET 
        `Money` = @money,
        `BankMoney` = @bankMoney,
        `PosX` = @posX,
        `PosY` = @posY,
        `PosZ` = @posZ,
        `PosA` = @posA,
        `Health` = @health,
        `Armour` = @armour,
        `Level` = @level,
        `Exp` = @exp,
        `PlayingHours` = @playingHours
        WHERE `ID` = @characterId
    ]]

    MySQL.query(query, {
        ['@money'] = data.Money,
        ['@bankMoney'] = data.BankMoney,
        ['@posX'] = data.Position.x,
        ['@posY'] = data.Position.y,
        ['@posZ'] = data.Position.z,
        ['@posA'] = data.Position.heading,
        ['@health'] = data.Health,
        ['@armour'] = data.Armour,
        ['@level'] = data.Level,
        ['@exp'] = data.Exp,
        ['@playingHours'] = data.PlayingHours,
        ['@characterId'] = data.CharacterID
    })
end

-- Function to create a new character
function createCharacter(source, accountId, name, age, gender, skin)
    local query = [[
        INSERT INTO `characters` (`AccountID`, `Name`, `Age`, `Gender`, `Skin`)
        VALUES (@accountId, @name, @age, @gender, @skin)
    ]]

    MySQL.query(query, {
        ['@accountId'] = accountId,
        ['@name'] = name,
        ['@age'] = age,
        ['@gender'] = gender,
        ['@skin'] = skin
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', source, "[SERVER]", { 0, 255, 0 }, "Character created successfully!")
            print(("[SC:RP] Character %s created for account ID %s"):format(name, accountId))
        end
    end)
end
