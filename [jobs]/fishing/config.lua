Config = {}

Config.StartJobLocation = vector3(-855.0, -136.0, 37.0) -- Location to start the fishing job
Config.SellLocation = vector3(-725.0, -1345.0, 5.0) -- Location to sell fish

Config.Checkpoints = {
    vector3(-900.0, -1400.0, 1.0),
    vector3(-1000.0, -1450.0, 1.0),
    vector3(-1100.0, -1500.0, 1.0),
    vector3(-1200.0, -1550.0, 1.0),
    vector3(-1300.0, -1600.0, 1.0)
}

Config.FishTypes = {
    {name = 'Salmon', price = 50},
    {name = 'Tuna', price = 75},
    {name = 'Cod', price = 30},
    {name = 'Bass', price = 20}
}

Config.ShopItems = {
    {name = 'Fishing Rod', price = 100},
    {name = 'Bait', price = 10}
}

Config.TimeToFish = 5000 -- ms