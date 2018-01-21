-- Imports
package.path = package.path .. ";../?.lua"
local m_hub_tv_lua = require("m-hub-tv-lua")

-- Settings to communicate with Broker (M-Hub-TV)
local settings = {}
settings.host_mhubtv = "localhost"
m_hub_tv_lua.setMqttSettings(settings)

local dataContext = m_hub_tv_lua.getContextDataTable()
local smartObjects = dataContext.smartobjects
local portableDevices = dataContext.portabledevices

-- Changing the physical ambient light
local dimmerlamps = smartObjects:filterByType('dimmerlamp')
for k, dm in pairs(dimmerlamps) do
	dm.functionality.controllfunctionality.intensityregulator.commandname = 'stepup'
	dm.functionality.controllfunctionality.intensityregulator.param.value = '5'
	dm.functionality.controllfunctionality.intensityregulator.param.unit = 'percent'
	m_hub_tv_lua.postSmartObject(dm)
end

-- Who is in the physical environment?
if(#portableDevices > 0)then
	for i = 1, #portableDevices do
		print(portableDevices[i].person.name)
	end
end
