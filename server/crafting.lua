-- Crafting system for SC:RP FiveM

CraftingRecipes = {
    ["medkit"] = {
        name = "Medkit",
        skillRequired = "crafting",
        skillLevel = 5,
        ingredients = {
            {item = "bandage", amount = 3},
            {item = "alcohol", amount = 1},
            {item = "herbs", amount = 2}
        },
        result = {item = "medkit", amount = 1}
    },
    ["lockpick"] = {
        name = "Lockpick",
        skillRequired = "crafting",
        skillLevel = 3,
        ingredients = {
            {item = "metal_scrap", amount = 2},
            {item = "plastic", amount = 1}
        },
        result = {item = "lockpick", amount = 1}
    },
    ["armor"] = {
        name = "Body Armor",
        skillRequired = "crafting",
        skillLevel = 10,
        ingredients = {
            {item = "kevlar", amount = 2},
            {item = "fabric", amount = 3},
            {item = "metal_plate", amount = 1}
        },
        result = {item = "armor", amount = 1}
    },
    ["repair_kit"] = {
        name = "Repair Kit",
        skillRequired = "mechanic",
        skillLevel = 5,
        ingredients = {
            {item = "metal_scrap", amount = 3},
            {item = "electronic_parts", amount = 1},
            {item = "tools", amount = 1}
        },
        result = {item = "repair_kit", amount = 1}
    },
    ["burger"] = {
        name = "Burger",
        skillRequired = "cooking",
        skillLevel = 3,
        ingredients = {
            {item = "meat", amount = 1},
            {item = "bread", amount = 1},
            {item = "lettuce", amount = 1}
        },
        result = {item = "burger", amount = 1}
    }
}

CraftingStations = {
    ["workbench"] = {
        name = "Workbench",
        recipes = {"lockpick", "repair_kit"}
    },
    ["medical_table"] = {
        name = "Medical Table",
        recipes = {"medkit"}
    },
    ["kitchen"] = {
        name = "Kitchen",
        recipes = {"burger"}
    },
    ["armor_bench"] = {
        name = "Armor Bench",
        recipes = {"armor"}
    }
}

-- Initialize crafting tables
function initializeCraftingTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `crafting_stations` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Type` varchar(32) NOT NULL,
            `LocationX` float NOT NULL,
            `LocationY` float NOT NULL,
            `LocationZ` float NOT NULL,
            `OwnerID` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
end

-- Function to load crafting stations
function loadCraftingStations()
    local query = [[
        SELECT * FROM `crafting_stations`
    ]]

    MySQL.query(query, {}, function(rows)
        local stations = {}
        for i = 1, #rows do
            local station = rows[i]
            table.insert(stations, {
                ID = station.ID,
                Type = station.Type,
                Location = {x = station.LocationX, y = station.LocationY, z = station.LocationZ},
                OwnerID = station.OwnerID
            })
        end
        
        -- Send to all clients
        TriggerClientEvent('scrp:updateCraftingStations', -1, stations)
    end)
end

-- Function to create a crafting station
function createCraftingStation(type, x, y, z, ownerId)
    if not CraftingStations[type] then return false end
    
    local query = [[
        INSERT INTO `crafting_stations` (`Type`, `LocationX`, `LocationY`, `LocationZ`, `OwnerID`)
        VALUES (@type, @x, @y, @z, @ownerId)
    ]]

    MySQL.query(query, {
        ['@type'] = type,
        ['@x'] = x,
        ['@y'] = y,
        ['@z'] = z,
        ['@ownerId'] = ownerId or 0
    }, function(rows, affected)
        if affected > 0 then
            loadCraftingStations()
            print(("[SC:RP] Crafting station %s created"):format(type))
        end
    end)
end

-- Function to craft an item
function craftItem(source, recipeId)
    if not PlayerData[source] or not CraftingRecipes[recipeId] then return false end
    
    local recipe = CraftingRecipes[recipeId]
    
    -- Check skill level
    if recipe.skillRequired and recipe.skillLevel > 0 then
        local skillLevel = getSkillLevel(source, recipe.skillRequired)
        if skillLevel < recipe.skillLevel then
            TriggerClientEvent('chatMessage', source, "[CRAFTING]", { 255, 0, 0 }, 
                ("You need %s level %d to craft this item!"):format(Skills[recipe.skillRequired].name, recipe.skillLevel))
            return false
        end
    end
    
    -- Check ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        local hasItem = false
        for _, item in ipairs(PlayerData[source].Inventory) do
            if item.ItemName == ingredient.item and item.Quantity >= ingredient.amount then
                hasItem = true
                break
            end
        end
        
        if not hasItem then
            TriggerClientEvent('chatMessage', source, "[CRAFTING]", { 255, 0, 0 }, 
                ("You don't have enough %s!"):format(ingredient.item))
            return false
        end
    end
    
    -- Remove ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        removeItemFromInventory(source, ingredient.item, ingredient.amount)
    end
    
    -- Add result
    addItemToInventory(source, recipe.result.item, recipe.result.amount)
    
    -- Add experience
    if recipe.skillRequired then
        addSkillExperience(source, recipe.skillRequired, 50)
    end
    
    TriggerClientEvent('chatMessage', source, "[CRAFTING]", { 0, 255, 0 }, 
        ("You crafted %dx %s!"):format(recipe.result.amount, recipe.name))
    
    return true
end

-- Function to get available recipes at a station
function getAvailableRecipes(stationType)
    if not CraftingStations[stationType] then return {} end
    
    local recipes = {}
    for _, recipeId in ipairs(CraftingStations[stationType].recipes) do
        if CraftingRecipes[recipeId] then
            table.insert(recipes, {
                id = recipeId,
                name = CraftingRecipes[recipeId].name,
                skillRequired = CraftingRecipes[recipeId].skillRequired,
                skillLevel = CraftingRecipes[recipeId].skillLevel,
                ingredients = CraftingRecipes[recipeId].ingredients,
                result = CraftingRecipes[recipeId].result
            })
        end
    end
    
    return recipes
end
