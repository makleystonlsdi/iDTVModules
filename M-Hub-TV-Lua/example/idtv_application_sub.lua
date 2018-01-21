-- Imports
package.path = package.path .. ";../?.lua"
local m_hub_tv_lua = require("m-hub-tv-lua")

-- Settings to communicate with Broker (M-Hub-TV)
local settings = {}
settings.host_mhubtv = "localhost"
m_hub_tv_lua.setMqttSettings(settings)
m_hub_tv_lua.setDebug(true)

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

local dimmerlamp = {}
dimmerlamp.environment = 'bedroom'
dimmerlamp.type = 'dimmerlamp'

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

m_hub_tv_lua.setSmartObjectsListener({presencesensor, dimmerlamp})
m_hub_tv_lua.setInteractionsListener({interactionLeft, interactionRight})
m_hub_tv_lua.start()