-- Imports
package.path = package.path .. ";../?.lua"
local lua_module = require("lua_module")

-- Settings to communicate with Broker (M-Hub-TV)
local settings = {}
settings.host_mhubtv = "localhost"
lua_module.setMqttSettings(settings)
lua_module.setDebug(true)

-- Defining the desirable smart objects for the application
local presencesensor = {}
presencesensor.environment = 'bedroom'
presencesensor.type = "presencesensor"
function presencesensor:receiveNotifications(notificationfunctionality)
	print("Notifications received")
end
function presencesensor:receiveStates(states)
	print("States received")
end

-- Defining the interactions supported by the application
local interactionLeft = {}
interactionLeft.name = 'Left'
interactionLeft.description = 'Move the portable device to the left'
function interactionLeft:detectedInteraction(device)
	print("The user "..device.person.name.." interacted by moving the portable device to the left")
end

local interactionRight = {}
interactionRight.name = 'Right'
interactionRight.description = 'Move the portable device to the right'
function interactionRight:detectedInteraction(device)
	print("The user "..device.person.name.." interacted by moving the portable device to the right")
end

lua_module.setSmartObjectsListener({presencesensor})
lua_module.setInteractionsListener({interactionLeft, interactionRight})
lua_module.start()