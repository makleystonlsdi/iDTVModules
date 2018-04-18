-- Imports
package.path = package.path .. ";../?.lua"
local CASMOC = require("CASMOC")

-- Settings to communicate with Broker (M-Hub-TV)
local settings = {}
settings.host_mhubtv = "192.168.10.36"
CASMOC.setMqttSettings(settings)

local dataContext = CASMOC.getContextDataTable()
local smartObjects = dataContext.smartobjects
local portableDevices = dataContext.portabledevices

-- Changing the physical ambient light
local dimmerlamps = smartObjects:filterByType('DimmerLamp')
for k, dm in pairs(dimmerlamps) do
	dm.Functionality.ControlFunctionality.LightRegulationFunctionality.Command.SetCommand.realStateValue = "0"
	CASMOC.postSmartObject(dm)
end

local ventilators = smartObjects:filterByType('Ventilator')
for k, v in pairs(ventilators) do
	v.Functionality.ControlFunctionality.OnOffFunctionality.Command.OnCommand.realStateValue = "off"
	CASMOC.postSmartObject(v)
end

-- Who is in the physical environment?
--[[if(#portableDevices > 0)then
	for i = 1, #portableDevices do
		print(portableDevices[i].Person.name)
	end
end]]
