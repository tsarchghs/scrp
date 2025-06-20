-- Database schema and initialization for SC:RP
-- Load order: Core tables first, then dependent tables

function initializeDatabase()
    print("[SC:RP] Initializing database tables...")
    
    -- Step 1: Create core tables without foreign keys
    createCoreTables()
    
    -- Step 2: Wait and create dependent tables
    SetTimeout(1000, function()
        createDependentTables()
    end)
end

-- Create core tables first (no foreign key dependencies)
function createCoreTables()
    -- Accounts table (no dependencies)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `accounts` (
            `AccountID` int(11) NOT NULL AUTO_INCREMENT,
            `Username` varchar(24) NOT NULL UNIQUE,
            `Password` varchar(128) NOT NULL,
            `Email` varchar(100) DEFAULT NULL,
            `RegisterDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `LastLogin` datetime DEFAULT NULL,
            `IP` varchar(45) DEFAULT NULL,
            `AdminLevel` int(2) DEFAULT 0,
            `IsBanned` tinyint(1) DEFAULT 0,
            `BanReason` text DEFAULT NULL,
            PRIMARY KEY (`AccountID`),
            INDEX `idx_username` (`Username`),
            INDEX `idx_ip` (`IP`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Characters table (depends on accounts)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `characters` (
            `CharacterID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `Name` varchar(24) NOT NULL UNIQUE,
            `Age` int(3) DEFAULT 25,
            `Gender` tinyint(1) DEFAULT 1,
            `Skin` int(11) DEFAULT 1,
            `Level` int(11) DEFAULT 1,
            `Experience` int(11) DEFAULT 0,
            `Money` int(11) DEFAULT 5000,
            `BankMoney` int(11) DEFAULT 10000,
            `Health` int(11) DEFAULT 100,
            `Armour` int(11) DEFAULT 0,
            `PosX` float DEFAULT 0.0,
            `PosY` float DEFAULT 0.0,
            `PosZ` float DEFAULT 0.0,
            `PosA` float DEFAULT 0.0,
            `Interior` int(11) DEFAULT 0,
            `VirtualWorld` int(11) DEFAULT 0,
            `JobID` int(11) DEFAULT 0,
            `JobRank` int(11) DEFAULT 0,
            `FactionID` int(11) DEFAULT 0,
            `FactionRank` int(11) DEFAULT 0,
            `AdminLevel` int(11) DEFAULT 0,
            `PlayingTime` int(11) DEFAULT 0,
            `LastLogin` datetime DEFAULT CURRENT_TIMESTAMP,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`CharacterID`),
            FOREIGN KEY (`AccountID`) REFERENCES `accounts`(`AccountID`) ON DELETE CASCADE,
            INDEX `idx_name` (`Name`),
            INDEX `idx_account` (`AccountID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Factions table (no dependencies)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `factions` (
            `FactionID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(50) NOT NULL,
            `Type` int(11) DEFAULT 0,
            `Color` varchar(7) DEFAULT '#FFFFFF',
            `MaxMembers` int(11) DEFAULT 50,
            `Budget` int(11) DEFAULT 0,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`FactionID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Jobs table (no dependencies)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `jobs` (
            `JobID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(50) NOT NULL,
            `Description` text DEFAULT NULL,
            `Salary` int(11) DEFAULT 1000,
            `MaxRank` int(11) DEFAULT 10,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`JobID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("[SC:RP] Core tables initialized.")
end

-- Create dependent tables (with foreign keys)
function createDependentTables()
    -- Bans table (depends on accounts)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `bans` (
            `BanID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `AdminName` varchar(24) NOT NULL,
            `Reason` text NOT NULL,
            `BanDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `UnbanDate` datetime DEFAULT NULL,
            `IsActive` tinyint(1) DEFAULT 1,
            PRIMARY KEY (`BanID`),
            FOREIGN KEY (`AccountID`) REFERENCES `accounts`(`AccountID`) ON DELETE CASCADE,
            INDEX `idx_account` (`AccountID`),
            INDEX `idx_active` (`IsActive`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Inventory table (depends on characters)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `inventory` (
            `InventoryID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `ItemName` varchar(50) NOT NULL,
            `Quantity` int(11) DEFAULT 1,
            `Slot` int(11) DEFAULT 0,
            PRIMARY KEY (`InventoryID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`CharacterID`) ON DELETE CASCADE,
            INDEX `idx_character` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Vehicles table (depends on characters)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vehicles` (
            `VehicleID` int(11) NOT NULL AUTO_INCREMENT,
            `OwnerID` int(11) DEFAULT 0,
            `Model` varchar(50) NOT NULL,
            `PosX` float DEFAULT 0.0,
            `PosY` float DEFAULT 0.0,
            `PosZ` float DEFAULT 0.0,
            `PosA` float DEFAULT 0.0,
            `Color1` int(11) DEFAULT 0,
            `Color2` int(11) DEFAULT 0,
            `Locked` tinyint(1) DEFAULT 1,
            `Fuel` float DEFAULT 100.0,
            `Engine` tinyint(1) DEFAULT 0,
            `Lights` tinyint(1) DEFAULT 0,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`VehicleID`),
            INDEX `idx_owner` (`OwnerID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Properties table (depends on characters)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `properties` (
            `PropertyID` int(11) NOT NULL AUTO_INCREMENT,
            `OwnerID` int(11) DEFAULT 0,
            `Type` int(11) DEFAULT 0,
            `Name` varchar(64) NOT NULL,
            `Price` int(11) DEFAULT 50000,
            `EntranceX` float NOT NULL,
            `EntranceY` float NOT NULL,
            `EntranceZ` float NOT NULL,
            `ExitX` float DEFAULT 0.0,
            `ExitY` float DEFAULT 0.0,
            `ExitZ` float DEFAULT 0.0,
            `Interior` int(11) DEFAULT 0,
            `Locked` tinyint(1) DEFAULT 1,
            `Rent` int(11) DEFAULT 0,
            `RentTime` datetime DEFAULT NULL,
            PRIMARY KEY (`PropertyID`),
            INDEX `idx_owner` (`OwnerID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Bank accounts table (depends on characters)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `bank_accounts` (
            `AccountID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `AccountNumber` varchar(16) NOT NULL UNIQUE,
            `Balance` int(11) DEFAULT 0,
            `PIN` varchar(4) NOT NULL,
            `Frozen` tinyint(1) DEFAULT 0,
            PRIMARY KEY (`AccountID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`CharacterID`) ON DELETE CASCADE,
            INDEX `idx_character` (`CharacterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Bank transactions table (depends on bank_accounts)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `bank_transactions` (
            `TransactionID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `Type` varchar(16) NOT NULL,
            `Amount` int(11) NOT NULL,
            `Description` varchar(128) DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`TransactionID`),
            FOREIGN KEY (`AccountID`) REFERENCES `bank_accounts`(`AccountID`) ON DELETE CASCADE,
            INDEX `idx_account` (`AccountID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Logs table (no dependencies)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `logs` (
            `LogID` int(11) NOT NULL AUTO_INCREMENT,
            `PlayerID` int(11) DEFAULT NULL,
            `PlayerName` varchar(24) DEFAULT NULL,
            `Action` varchar(50) NOT NULL,
            `Details` text DEFAULT NULL,
            `IP` varchar(45) DEFAULT NULL,
            `Timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`LogID`),
            INDEX `idx_player` (`PlayerID`),
            INDEX `idx_action` (`Action`),
            INDEX `idx_timestamp` (`Timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("[SC:RP] All database tables initialized successfully!")
end

-- Database connection function for mysql-async v3.3.2
function connectToDatabase()
    MySQL.ready(function()
        print("[SC:RP] Connected to database via mysql-async v3.3.2")
        print("[SC:RP] Database connection established successfully!")
        print("[SC:RP] Using mysql-async version 3.3.2")
    end)
end
