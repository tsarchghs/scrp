local isLoggedIn = false
local helpVisible = false

-- Function to show the help text
function showHelpText()
    if helpVisible then return end
    helpVisible = true
    SendNUIMessage({
        type = 'showHelp',
        style = Config.HelpTextStyle,
        message = Config.Messages.LoginHelp
    })
end

-- Function to hide the help text
function hideHelpText()
    if not helpVisible then return end
    helpVisible = false
    SendNUIMessage({type = 'hideHelp'})
end

-- Event to show help text from the server
RegisterNetEvent('authentication:showHelp')
AddEventHandler('authentication:showHelp', function()
    showHelpText()
end)

-- Event for successful login
RegisterNetEvent('authentication:loginSuccess')
AddEventHandler('authentication:loginSuccess', function()
    isLoggedIn = true
    hideHelpText()
    -- Allow the player to spawn
    ShutdownLoadingScreen()
    TriggerEvent('spawnmanager:spawnPlayer')
end)

-- Main thread
CreateThread(function()
    -- This is a bit of a hack to prevent the default spawn.
    -- A better solution would be to have a custom spawn manager that respects the login status.
    while not isLoggedIn do
        Wait(0)
        -- Freeze the player
        FreezeEntityPosition(PlayerPedId(), true)
        -- Hide the HUD
        DisplayRadar(false)
        -- Show the help text
        showHelpText()
        -- Prevent the default spawn
        if IsPlayerSpawned() then
            -- This is not ideal, but it's a simple way to prevent the player from moving around.
            SetEntityCoords(PlayerPedId(), 0.0, 0.0, 1000.0, false, false, false, false)
        end
    end
end)

-- NUI Focus
CreateThread(function()
    while true do
        Wait(0)
        if helpVisible then
            SetNuiFocus(true, true)
        else
            SetNuiFocus(false, false)
        end
    end
end)

-- Create a simple NUI page to display the help text
-- This is a very basic implementation. A more advanced solution would use a proper HTML/CSS/JS UI.
function CreateNuiPage()
    local html = [[
        <html>
            <head>
                <script src="nui://game/ui/jquery.js" type="text/javascript"></script>
                <script>
                    $(function() {
                        window.addEventListener('message', function(event) {
                            if (event.data.type === 'showHelp') {
                                let style = '';
                                for (const [key, value] of Object.entries(event.data.style)) {
                                    style += `${key.replace(/([A-Z])/g, '-$1').toLowerCase()}:${value};`;
                                }
                                $('body').html(`<div id="help" style="${style}">${event.data.message}</div>`);
                                $('#help').fadeIn();
                            } else if (event.data.type === 'hideHelp') {
                                $('#help').fadeOut();
                            }
                        });
                    });
                </script>
            </head>
            <body></body>
        </html>
    ]]
    
    -- This is a bit of a hack to create a data file URI for the NUI page.
    -- A better solution would be to have a proper HTML file in the resource.
    local data = "data:text/html;charset=utf-8," .. html:gsub("\n", ""):gsub("\r", ""):gsub(" ", "%%20")
    
    -- This is not a standard FiveM function, but it's a way to set the NUI page content.
    -- In a real resource, you would use a proper HTML file.
    SendNUIMessage({
        type = 'createPage',
        html = data
    })
end

-- Create the NUI page when the resource starts
CreateNuiPage()