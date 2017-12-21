local x = require ("lua_module")

local t = x.getTableSmartObject()

function printTableSmartObject(t)
	for k,table in pairs(t) do
		print("\n-------------------------------------")
		print("Mac: "..table.mac)
		print("Type: "..table.type)
		print("Controllable: "..table.controllable)
		--print("Ambiente físico: "..table[i].environment)
		print("DateTime: "..table.clock)
		print("States: ")
		print("-------------------------------------")

		if(table.state)then
			for kState,vState in pairs(table.state) do
				print("State: "..kState)
				for kStateValue,vStateValue in pairs(table.state[kState].state_value) do
					print("State Value: "..kStateValue)
					print("Value: "..vStateValue.value)
					print("Unit: "..vStateValue.unit)
				end
				print("-------------------------------------")
			end
		end
	end
end

--printTableSmartObject()
x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&DimmerLamp&10")
x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&PresenceSensor&12")
x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&y&13")
x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&X&11")
x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&Lamp&10")
--printTableSmartObject(t)
x.main("/reserved_topic/smart_object_disconnected", "13")

x.main("/reserved_topic/smart_object_discovered", "Bedroom&Actuator&Lamp&10")


t1 = x.getTableSmartObject()
printTableSmartObject(t1)