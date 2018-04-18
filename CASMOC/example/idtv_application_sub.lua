-- Imports
package.path = package.path .. ";../?.lua"
local CASMOC = require("CASMOC")

-- Settings to communicate with Broker (M-Hub-TV)
local settings = {}
settings.host_master = "192.168.0.18"
CASMOC.setMqttSettings(settings)

-- Defining the desirable smart objects for the application
local presencesensor = {}
presencesensor.Environment = 'Bedroom'
presencesensor.Type = "PresenceSensor"
function presencesensor:receiveNotification(NotificationFunctionality)
	if(NotificationFunctionality['PresenceNotificationFunctionality'].Notification['IsPresentNotification'])then
		print("Tem gnt na sala")
	else
		print("Não há pessoas na sala")
	end
end

local smartobjects = {presencesensor}
-- End

-- Defining the interactions supported by the application
local events = {}
function events:receiveEvents(Portable, Events)
	for i = 1, #Events do
		print("The user "..Portable.Person.givenName.." interacted by performing the "..Events[i].." action through the "..Portable.Type.." portable device")
	end
end
-- End

-- Associates the execution functions of smart objects with another smart object of the same type.
local smartObjectSwitch = {}
function smartObjectSwitch:smartObjectSwitch(currentSmartObjects, newSmartObject)
	newSmartObject.receiveNotifications = currentSmartObjects[1].receiveNotifications
end
-- End

CASMOC.setSmartObjectsListener(smartobjects, smartObjectSwitch)
CASMOC.setEventsListener(events)
CASMOC.start()