-- Faction system

Factions = {}

-- Function to load all factions
function loadFactions()
    local query = [[
        SELECT * FROM `factions`
    ]]

    MySQL.query(query, {}, function(rows)
        Factions = {}
        for i = 1, #rows do
            local faction = rows[i]
            Factions[faction.ID] = {
                ID = faction.ID,
                Name = faction.Name,
                Type = faction.Type,
                Color = faction.Color,
                MOTD = faction.MOTD,
                Budget = faction.Budget,
                MaxMembers = faction.MaxMembers,
                Members = {}
            }
        end
        print(("[SC:RP] Loaded %d factions"):format(#rows))
    end)
end

-- Function to create a faction
function createFaction(name, type, color)
    local query = [[
        INSERT INTO `factions` (`Name`, `Type`, `Color`)
        VALUES (@name, @type, @color)
    ]]

    MySQL.query(query, {
        ['@name'] = name,
        ['@type'] = type,
        ['@color'] = color
    }, function(rows, affected)
        if affected > 0 then
            loadFactions() -- Reload factions
            print(("[SC:RP] Faction %s created"):format(name))
        end
    end)
end

-- Function to invite player to faction
function inviteToFaction(source, targetSource, factionId, rank)
    if not PlayerData[source] or not PlayerData[targetSource] then return end
    if not Factions[factionId] then return end
    
    local targetCharacterId = PlayerData[targetSource].CharacterID
    local query = [[
        UPDATE `characters` SET `FactionID` = @factionId, `FactionRank` = @rank
        WHERE `ID` = @characterId
    ]]

    MySQL.query(query, {
        ['@factionId'] = factionId,
        ['@rank'] = rank,
        ['@characterId'] = targetCharacterId
    }, function(rows, affected)
        if affected > 0 then
            PlayerData[targetSource].FactionID = factionId
            PlayerData[targetSource].FactionRank = rank
            
            local factionName = Factions[factionId].Name
            TriggerClientEvent('chatMessage', targetSource, "[FACTION]", { 255, 255, 0 }, 
                ("You have been invited to %s!"):format(factionName))
            TriggerClientEvent('chatMessage', source, "[FACTION]", { 255, 255, 0 }, 
                ("You invited %s to %s"):format(PlayerData[targetSource].Name, factionName))
        end
    end)
end
