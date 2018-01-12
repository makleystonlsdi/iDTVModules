local lua_module = require ("lua_module")

local mqtt_settings = {}
mqtt_settings.host_mhubtv = '192.168.0.10'
lua_module.setMqttSettings(mqtt_settings)

local dimmerLampsList = lua_module.getSmartObjectsByType('dimmerlamp')

for key, object in pairs(dimmerLampsList) do
	object.functionality['intensityregulatorfunctionality'].command['stepup'] = 0.05
	object.functionality['colorchangefunctionality'].command['color'] = 'red'	
	dimmerLampsList[key] = object
end

lua_module.postSmartObjectsList(dimmerLampsList)