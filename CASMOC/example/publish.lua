--
-- Created by IntelliJ IDEA.
-- User: makleyston
-- Date: 18/01/18
-- Time: 17:05
-- To change this template use File | Settings | File Templates.
--

package.path = package.path .. ";../?.lua"
package.path = package.path .. ";../libs/?.lua"

local lua_module = require ('m-hub-tv-lua')
local json = require ('json_lua')

-- Settings
local settings = {}
settings.host_mhubtv = "localhost"
settings.id = "publish"
lua_module.setMqttSettings(settings)

local presencesensor = {}
local presencesensor2 = {}
local dimmerlamp = {}
local temperaturesensor = {}

presencesensor.id = 'presenceID1'
presencesensor.environment = 'bedroom'
presencesensor.controllable = 'sensor'
presencesensor.type = 'presencesensor'
presencesensor.functionality = {}
presencesensor.functionality.notificationfunctionality = {}
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality = {}
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality.notificationname = 'isPresent'
presencesensor.functionality.notificationfunctionality.presencenotificationfunctionality.value = 'isPresent'
presencesensor.state = {}
presencesensor.state.presencestate = {}
presencesensor.state.presencestate.value = 'present'
presencesensor.state.presencestate.unit = 'discret'

presencesensor2.id = 'presenceID2'
presencesensor2.environment = 'bedroom'
presencesensor2.controllable = 'sensor'
presencesensor2.type = 'presencesensor'
presencesensor2.functionality = {}
presencesensor2.functionality.notificationfunctionality = {}
presencesensor2.functionality.notificationfunctionality.presencenotificationfunctionality = {}
presencesensor2.functionality.notificationfunctionality.presencenotificationfunctionality.notificationname = 'isPresent'
presencesensor2.functionality.notificationfunctionality.presencenotificationfunctionality.value = 'isPresent'
presencesensor2.state = {}
presencesensor2.state.presencestate = {}
presencesensor2.state.presencestate.value = 'present'
presencesensor2.state.presencestate.unit = 'discret'

local presencesensor3 = {}
presencesensor3.id = 'presenceID3'
presencesensor3.environment = 'bedroom'
presencesensor3.controllable = 'sensor'
presencesensor3.type = 'presencesensor'
presencesensor3.functionality = {}
presencesensor3.functionality.notificationfunctionality = {}
presencesensor3.functionality.notificationfunctionality.presencenotificationfunctionality = {}
presencesensor3.functionality.notificationfunctionality.presencenotificationfunctionality.notificationname = 'isPresent'
presencesensor3.functionality.notificationfunctionality.presencenotificationfunctionality.value = 'isPresent'
presencesensor3.state = {}
presencesensor3.state.presencestate = {}
presencesensor3.state.presencestate.value = 'present'
presencesensor3.state.presencestate.unit = 'discret'

temperaturesensor.id = 'temperatureID'
temperaturesensor.environment = 'bedroom'
temperaturesensor.controllable = 'sensor'
temperaturesensor.type = 'temperaturesensor'
temperaturesensor.functionality = {}
temperaturesensor.functionality.notificationfunctionality = {}
temperaturesensor.functionality.notificationfunctionality.x = {}
temperaturesensor.functionality.notificationfunctionality.x.notificationname = ''
temperaturesensor.functionality.notificationfunctionality.x.value = ''
temperaturesensor.state = {}
temperaturesensor.state.temperaturestate = {}
temperaturesensor.state.temperaturestate.value = '23'
temperaturesensor.state.temperaturestate.unit = 'C'

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
dimmerlamp.functionality.controllfunctionality.intensityregulator.param.value = ''
dimmerlamp.functionality.controllfunctionality.intensityregulator.param.unit = 'percent'
dimmerlamp.state = {}
dimmerlamp.state.intensitystate = {}
dimmerlamp.state.intensitystate.value = '0.5'
dimmerlamp.state.intensitystate.unit = 'continuos'

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
device.type = "smartphone"
device.events = {right, left}

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
--
-- -- lua_module.postMessage('/smart_object_discovery'..getTopic(presencesensor), presencesensor)
lua_module.postMessage('/smart_object_read'..getTopic(presencesensor), presencesensor)
lua_module.postMessage('/smart_object_read'..getTopic(presencesensor2), presencesensor2)
lua_module.postMessage('/smart_object_read'..getTopic(presencesensor3), presencesensor3)
--lua_module.postMessage('/smart_object_read'..getTopic(dimmerlamp), dimmerlamp)
lua_module.postMessage('/smart_object_read'..getTopic(temperaturesensor), temperaturesensor)
--print('/smart_object_disconnected'..getTopic(presencesensor), presencesensor.id)
--lua_module.postMessage('/smart_object_disconnected'..getTopic(presencesensor), presencesensor.id)
lua_module.postMessage('/portable_device_receiver'..getTopic(nil, device), device)
--print('/portable_device_receiver'..getTopic(nil, device))

--local t = "Oi+"
--lua_module.postMessage('/get_system_params', t)



local obj = {}
obj.id = ''
obj.environment = ''
obj.type = ''
obj.controllable = ''
obj.functionality = {}
obj.functionality.controllfunctionality = {}
obj.functionality.notificationfunctionality = {}
obj.functionality.queryfunctionality = {}
obj.state = {}






