-- Inventory system

-- Function to load player inventory
function loadPlayerInventory(source, characterId)
    local query = [[
        SELECT * FROM `inventory` WHERE `CharacterID` = @characterId
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId
    }, function(rows)
        if PlayerData[source] then
            PlayerData[source].Inventory = {}
            for i = 1, #rows do
                local item = rows[i]
                table.insert(PlayerData[source].Inventory, {
                    ID = item.ID,
                    ItemName = item.ItemName,
                    Quantity = item.Quantity,
                    Data = item.Data
                })
            end
            print(("[SC:RP] Loaded %d inventory items for character %d"):format(#rows, characterId))
        end
    end)
end

-- Function to add item to inventory
function addItemToInventory(source, itemName, quantity, data)
    if not PlayerData[source] then return false end
    
    local characterId = PlayerData[source].CharacterID
    local query = [[
        INSERT INTO `inventory` (`CharacterID`, `ItemName`, `Quantity`, `Data`)
        VALUES (@characterId, @itemName, @quantity, @data)
    ]]

    MySQL.query(query, {
        ['@characterId'] = characterId,
        ['@itemName'] = itemName,
        ['@quantity'] = quantity,
        ['@data'] = data or ''
    }, function(rows, affected)
        if affected > 0 then
            -- Add to local inventory
            table.insert(PlayerData[source].Inventory, {
                ItemName = itemName,
                Quantity = quantity,
                Data = data
            })
            TriggerClientEvent('scrp:updateInventory', source, PlayerData[source].Inventory)
            return true
        end
        return false
    end)
end

-- Function to remove item from inventory
function removeItemFromInventory(source, itemName, quantity)
    if not PlayerData[source] then return false end
    
    local characterId = PlayerData[source].CharacterID
    
    -- Find item in inventory
    for i, item in ipairs(PlayerData[source].Inventory) do
        if item.ItemName == itemName then
            if item.Quantity >= quantity then
                local newQuantity = item.Quantity - quantity
                
                if newQuantity <= 0 then
                    -- Remove item completely
                    local query = [[
                        DELETE FROM `inventory` WHERE `CharacterID` = @characterId AND `ItemName` = @itemName
                    ]]
                    MySQL.query(query, {
                        ['@characterId'] = characterId,
                        ['@itemName'] = itemName
                    })
                    table.remove(PlayerData[source].Inventory, i)
                else
                    -- Update quantity
                    local query = [[
                        UPDATE `inventory` SET `Quantity` = @quantity 
                        WHERE `CharacterID` = @characterId AND `ItemName` = @itemName
                    ]]
                    MySQL.query(query, {
                        ['@quantity'] = newQuantity,
                        ['@characterId'] = characterId,
                        ['@itemName'] = itemName
                    })
                    PlayerData[source].Inventory[i].Quantity = newQuantity
                end
                
                TriggerClientEvent('scrp:updateInventory', source, PlayerData[source].Inventory)
                return true
            end
            break
        end
    end
    return false
end
