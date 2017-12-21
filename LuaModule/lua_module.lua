local lua_module = {}

-- Tables
local tableSmartObjects = {}
local tablePortableDevices = {}
local tableInteractions = {}

-- Global variables
local sepCharTopic = "/"
local sepCharMsg = "&";
--local t = os.date("*t")
local clock = os.clock()
--local time = ("%02d:%02d:%02d"):format(t.hour, t.min, t.sec)
--local date = ("%02d/%02d/%04d"):format(t.month, t.day, t.year)

function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

--Returned the index of smar object in table
function lua_module.searchSmartObject(mac)
	for k,v in pairs(tableSmartObjects) do
		if(mac == v.mac) then
			return k
		end
	end
	return nil
end

function lua_module.getTableSmartObject()
	return tableSmartObjects
end

function lua_module.setTableInteracions(table)
	tableInteractions = table
end

function lua_module.getTableInteracions()
	return tableInteractions
end

function updateDateTime(indexObj)
	tableSmartObjects[indexObj].clock = clock
	--tableSmartObjects[indexObj].date = date
	--tableSmartObjects[indexObj].time = time
end

function lua_module.printTableSmartObject()
	for i=1,#tableSmartObjects do
		print("\n-------------------------------------")
		print("Mac: "..tableSmartObjects[i].mac)
		print("Type: "..tableSmartObjects[i].type)
		print("Controllable: "..tableSmartObjects[i].controllable)
		print("Ambiente físico: "..tableSmartObjects[i].environment)
		print("DateTime: "..tableSmartObjects[i].clock)
		print("States: ")
		print("-------------------------------------")

		for kState,vState in pairs(tableSmartObjects[i].state) do
			print("State: "..kState)
			for kStateValue,vStateValue in pairs(tableSmartObjects[i].state[kState].state_value) do
				print("State Value: "..kStateValue)
				print("Value: "..vStateValue.value)
				print("Unit: "..vStateValue.unit)
			end
			print("-------------------------------------")
		end
	end
end

function addSmartObjectInTable(obj)
	tableSmartObjects[#tableSmartObjects + 1] = obj
end

function removeSmartObjectInTable(index)
	tableSmartObjects.remove(tableSmartObjects, index)
end

function updateState(indexObj, structTopic, structMsg)
	tableSmartObjects[indexObj].environment = structTopic[1]
	tableSmartObjects[indexObj].state = {}
	tableSmartObjects[indexObj].state[structTopic[5]] = {}
	tableSmartObjects[indexObj].state[structTopic[5]].state_value = {}
	tableSmartObjects[indexObj].state[structTopic[5]].state_value[structTopic[6]] = {
		['value'] = structMsg[2],
		['unit'] = structMsg[3]
	}
	updateDateTime(indexObj)
end

function updateFunctionalityNotification(indexObj, structTopic, structMsg)
	tableSmartObjects[indexObj].environment = structTopic[1]
	tableSmartObjects[indexObj].functionality_notification[structTopic[5]].notification[structTopic[6]] = {
		['notification_name'] = structMsg[1]
	}
	updateDateTime(indexObj)
end

function updateFunctionalityCommand(indexObj, structTopic, structMsg)
	tableSmartObjects[indexObj].environment = structTopic[1]
	tableSmartObjects[indexObj].functionality_command[structTopic[5]].command[structTopic[6]] = { 
		['unit'] = structMsg[2]
	}
	updateDateTime(indexObj)
end

function updateProtableDevces(...)
	-- body
end

function readDataSmartObject(t, m)
	--Example of topic
	--Topic: /Environment/Controllable/Type/Id/State/StateValue
	--Topic: /Environment/Controllable/Type/Id/Functionality/Notification
	--Topic: /Environment/Controllable/Type/Id/Functionality/Command
	local topic =  t or ""
	local msg = m or ""

	local structTopic = split(topic, sepCharTopic)
	local structMsg = split(msg, sepCharMsg)

	local indexObj = searchSmartObject(structTopic[4])

	if(indexObj == nil) then
		--Non-existing object
		local obj = {
			['mac'] = structTopic[4],
			['controllable'] = structTopic[2],
			['type'] = structTopic[3]
		}
		addSmartObjectInTable(obj)
		indexObj = #tableSmartObjects
	end
	
	if(structMsg[1] == "State") then
		updateState(indexObj, structTopic, structMsg)
	elseif (structMsg[1] == "FunctionalityNotification") then
	    updateFunctionalityNotification(indexObj, structTopic, structMsg)
	elseif (structMsg[1] == "FunctionalityCommand") then
	    updateFunctionalityCommand(indexObj, structTopic, structMsg)
	end
end

function discoverySmartObject(m)
	--Example of msg
	--msg: Environment&Controllable&Type&Id
	local structMsg = split(m, sepCharMsg)
	local indexObj = lua_module.searchSmartObject(structMsg[4]) --Mac - ID

	if(indexObj == nil) then
		--Non-existing object
		local obj = {
			['mac'] = structMsg[4],
			['controllable'] = structMsg[2],
			['type'] = structMsg[3]
		}
		addSmartObjectInTable(obj)
		indexObj = #tableSmartObjects
		updateDateTime(indexObj)
	end
end

function disconnectSmartObject(m)
	--Example of msg
	--msg: Id (Mac)
	local indexObj = lua_module.searchSmartObject(m) --Mac - ID
	if (indexObj ~= nil) then
		tableSmartObjects[indexObj] = nil
	end
end

function lua_module.main(t, m)
	print(t, m)
	local topic = t or ""
	local msg = m or ""
	local switch = {
		['/reserved_topic/smart_object_discovered'] = function()
			discoverySmartObject(msg)
		end,
		['/reserved_topic/smart_object_disconnected'] = function()
			disconnectSmartObject(msg)
		end,
		['/reserved_topic/result_query'] = function()
			print "Test: ok"
		end,
		['/reserved_topic/user_interaction/is_living'] = function()
			print "Test: ok"
		end,
		['/reserved_topic/user_interaction/interaction'] = function()
			print "Test: ok"
		end,
		['/reserved_topic/test'] = function()
			print "Test: ok"
		end
	}

	local f = switch[topic]

	if(f) then
		f()
	else				-- for case default
		
	end

end

function lua_module.main2()
	local op
	repeat
		print("*****************************************************************")
		print("1 - Simular entrada de dados")
		print("2 - Simulçar saida de dados")
		print("3 - Imprimir os Smart Objects da tabela")
		print("0 - Exit")
		print("*****************************************************************")
		print(time)
		print(date)
		op = io.stdin:read'*l'
		if(op == '1') then
			print("Digite o topic")
			local t = io.stdin:read'*l'
			print("Digite a msg")
			local m = io.stdin:read'*l'
			discoverySmartObject(t, m)
		elseif (op == '2') then
			local sub = io.stdin:read'*l'
		elseif (op == '3') then 
			printTableSmartObject()
		end
	until op == '0'
end

return lua_module

--main()
