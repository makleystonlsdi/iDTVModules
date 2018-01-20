--
-- Created by IntelliJ IDEA.
-- User: makleyston
-- Date: 18/01/18
-- Time: 17:05
-- To change this template use File | Settings | File Templates.
--

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";../libs/?.lua"

local lua_module = require ('lua_module')
local json = require ('json_lua')

-- Settings
local settings = {}
settings.host_mhubtv = "localhost"
settings.id = "publish"
lua_module.setMqttSettings(settings)

local presencesensor = {}
local dimmerlamp = {}
local temperaturesensor = {}

presencesensor.id = 'presenceID'
presencesensor.environment = 'bedroom'
presencesensor.controllable = 'sensor'
presencesensor.type = 'presencesensor'
presencesensor.functionality = {}
presencesensor.functionality.notificationfunctionality = {}
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality = {}
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality.notificationname = 'isPresent'
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality.value = 'isPresent'
presencesensor.states = {}
presencesensor.states.presencestate = {}
presencesensor.states.presencestate.value = 'present'
presencesensor.states.presencestate.unit = 'discret'

temperaturesensor.id = 'temperatureID'
temperaturesensor.environment = 'bedroom'
temperaturesensor.controllable = 'sensor'
temperaturesensor.type = 'temperaturesensor'
temperaturesensor.functionality = {}
temperaturesensor.functionality.notificationfunctionality = {}
temperaturesensor.functionality.notificationfunctionality.x = {}
temperaturesensor.functionality.notificationfunctionality.x.notificationname = ''
temperaturesensor.functionality.notificationfunctionality.x.value = ''
temperaturesensor.states = {}
temperaturesensor.states.temperaturestate = {}
temperaturesensor.states.temperaturestate.value = '23'
temperaturesensor.states.temperaturestate.unit = 'C'

dimmerlamp.id = 'dimmerlampID'
dimmerlamp.environment = 'bedroom'
dimmerlamp.controllable = 'actuator'
dimmerlamp.type = 'dimmerlamp'
dimmerlamp.functionality = {}
dimmerlamp.functionality.notificationfunctionality = {}
dimmerlamp.functionality.notificationfunctionality.notificationname = ''
dimmerlamp.functionality.notificationfunctionality.value = ''
dimmerlamp.functionality.controllfunctionality = {}
dimmerlamp.functionality.controllfunctionality.intensityregulator = {}
dimmerlamp.functionality.controllfunctionality.intensityregulator.commandname = 'stepup'
dimmerlamp.functionality.controllfunctionality.intensityregulator.param = {}
dimmerlamp.functionality.controllfunctionality.intensityregulator.param.value = '0.05'
dimmerlamp.functionality.controllfunctionality.intensityregulator.param.unit = 'continuos'
dimmerlamp.states = {}
dimmerlamp.states.intensitystate = {}
dimmerlamp.states.intensitystate.value = '0.5'
dimmerlamp.states.intensitystate.unit = 'continuos'

local objs = {}
table.insert(objs, presencesensor)
table.insert(objs, temperaturesensor)
table.insert(objs, dimmerlamp)

local person = {}
person.uuid = 'personUUID'
person.name = 'Danne'
person.genre = 'Male'

local left = {['name'] = 'Left'}
local right = {['name'] = 'Right'}

local device = {}
device.id = 'deviceID'
device.environment = 'bedroom'
device.person = person
device.interactions = {right, left}

function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function getTopic(obj, portable)
	if(portable == nil)then
		return '/'..obj.environment..'/'..obj.controllable..'/'..obj.type
	else
		return '/'..portable.environment
	end
end

function loop()
	for k, v in pairs(objs) do
		print('/smart_object_discovery'..getTopic(v), v)
		lua_module.postMessage('/smart_object_discovery'..getTopic(v), v)
	end
end

--loop()
--lua_module.postMessage('/smart_object_discovery'..getTopic(presencesensor), presencesensor)
--lua_module.postMessage('/smart_object_read'..getTopic(presencesensor), presencesensor)
--print('/smart_object_disconnected'..getTopic(presencesensor), presencesensor.id)
--lua_module.postMessage('/smart_object_disconnected'..getTopic(presencesensor), presencesensor.id)
lua_module.postMessage('/portable_device_receiver'..getTopic(nil, device), device)
--print('/portable_device_receiver'..getTopic(nil, device))

















