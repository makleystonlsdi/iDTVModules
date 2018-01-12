local json = require("json_lua")
local lua_module = {}

-- Tables
local smartObjectsTable = {}
local portableDevicesTable = {}
local interactionsTable = {}
local topicsTable = {}

-- MQTT Settings
local mqtt_settings ={
		['host_mhubtv'] = "",
	  ['id'] = "iDTV",
	  ['port'] = 1883,
	  ['topic_sub'] = "/#",
	  ['topic_pub'] = "/reservedtopic/test",
    ['topic_separator_character'] = "/",
    ['message_separator_character'] = "&",
    ['time_active_portable_devices'] = 20 --seconds
  } 

-- *******************************************
-- ****** Global methods of this module ******
-- *******************************************
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

function updateDateTime(table, indexObj)
	local clock = os.clock()
	table[indexObj].clock = clock
end

--If is alive then it returns true, if it does not return false
function calcDiffClock(clockInit, clockEnd)
	if(clockEnd - clockInit) <= mqtt_settings.time_active_portable_devices then
		return true
	else
		return false
	end
end

-- Set MQTT Settings
function lua_module.setMqttSettings(settings)
	for k,v in pairs(settings) do
		mqtt_settings[k] = v
	end
end

function lua_module.getMqttSettings()
	return mqtt_settings
end






-- **************************************
-- ****** Methods to Smart Objects ******
-- **************************************
function lua_module.getSmartObjectsTable()
	return smartObjectsTable
end
--Returned the index of smart object in table
function getIndexSmartObjectById(id)
	for k,v in pairs(smartObjectsTable) do
    --print(id..' - '..v.ID)
		if(id == v.ID) then
			return k
		end
	end
	return nil
end

--Returned the indexs of smart objects in table
function lua_module.getIndexSmartObjectByType(type)
	for k,v in pairs(smartObjectsTable) do
		if(type == v.type) then
			return k
		end
	end
	return nil
end

function lua_module.printTableSmartObject()
	for i=1,#smartObjectsTable do
		print("\n-------------------------------------")
		print("ID: "..smartObjectsTable[i].ID)
		print("Type: "..smartObjectsTable[i].type)
		print("Controllable: "..smartObjectsTable[i].controllable)
		print("Ambiente físico: "..smartObjectsTable[i].environment)
		print("DateTime: "..smartObjectsTable[i].clock)
		print("States: ")
		print("-------------------------------------")

		for kState,vState in pairs(smartObjectsTable[i].state) do
			print("State: "..kState)
			for kStateValue,vStateValue in pairs(smartObjectsTable[i].state[kState].state_value) do
				print("State Value: "..kStateValue)
				print("Value: "..vStateValue.value)
				print("Unit: "..vStateValue.unit)
			end
			print("-------------------------------------")
		end
	end
end

function addSmartObject(obj)
	smartObjectsTable[#smartObjectsTable + 1] = obj
end

function removeSmartObject(index)
	smartObjectsTable.remove(smartObjectsTable, index)
end

function discoverySmartObject(m)
	--Example of msg
  --msg: json object
  local obj = json.decode(m)
	local indexObj = getIndexSmartObjectById(obj.ID) --Mac - ID

	if(indexObj == nil) then
		--Non-existing object
		addSmartObject(obj)
		indexObj = #smartObjectsTable
		updateDateTime(smartObjectsTable, indexObj)
	end
end

function disconnectSmartObject(idObj)
	--Example of msg
	--msg: Id (Mac)
	local indexObj = getIndexSmartObjectById(idObj) --Mac - ID
	if (indexObj ~= nil) then
		smartObjectsTable[indexObj] = nil
	end
end

function updateSmartObject(obj)
  local indexObj = getIndexSmartObjectById(obj.ID)
  
  if(indexObj == nil) then return end
  
  local so = smartObjectsTable[indexObj]
  if (so.environment ~= obj.environment) then
    so.environment = obj.environment
  end
  
  for k, v in pairs(obj.states) do
    if (so.states[k].unit ~= obj.states[k].unit) then
      so.states[k].unit = obj.states[k].unit
    end
    if (so.states[k].value ~= obj.states[k].value) then
      so.states[k].value = obj.states[k].value
    end
  end
end

function receiveDataSmartObject(m)
	--Example of topic
	--Topic: /Environment/Controllable/Type
  if (m == nil) then return end
	local obj = json.decode(m)
	local indexObj = getIndexSmartObjectById(obj.ID)
	--If non-existing smart object
	if(indexObj == nil) then 
    return
  end 
  updateSmartObject(obj)
end
-- *** End of methods to Smart Objects ***





-- *************************************
-- ****** Methods to Interactions ******
-- *************************************
function lua_module.setTableInteracions(table)
	tableInteractions = table
end

function lua_module.getTableInteracions()
	return tableInteractions
end

function lua_module.searchInteraction(interaction_name)
	for k,v in pairs(tableInteractions) do
		if(interaction_name == v) then
			return k
		end
	end
	return nil
end
-- ****** Methods to Interactions ******





-- *****************************************
-- ****** Methods to Portable Devices ******
-- *****************************************
--Returned the index of portable device in table
function lua_module.searchPortableDevice(mac)
	for k,v in pairs(tablePortableDevces) do
		if(mac == v.mac) then
			return k
		end
	end
	return nil
end

function lua_module.printTablePortableDevices()
	-- body
end

function addProtableDevice(dev)
	tablePortableDevices[#tablePortableDevices + 1] = dev
end

function removePortableDevice(mac)
	local indexDev = lua_module.searchPortableDevice(mac)
	if (indexDev) then
		tablePortableDevices[indexDev] = nil
	end
end

function lua_module.getTablePortableDevice()
	for k,v in pairs(tablePortableDevices) do
		--If is alive
		if (calcClock(v.clock, os.clock()) == false) then
			removePortableDevice(v.mac)
		end
	end
	return tablePortableDevices
end

function discoveryPortableDevices(t, m)
	--Example of topic
	--/Environment/Controllable/TypePortable/Id/Person
	local topic = t or ""
	local msg = m or ""

	local structTopic = split(topic, sepCharTopic)
	local indexDev = lua_module.searchPortableDevice(structTopic[4])

	if(indexDev == nil) then
		--Non-existing object
		local dev = {
			['mac'] = structMsg[4],
			['controllable'] = structMsg[2],
			['type'] = structMsg[3],
			['environment'] = structMsg[1],
			['person'] = structMsg[5]
		}
		addProtableDevice(dev)
		indexDev = #tablePortableDevices
		updateDateTime(tablePortableDevices, indexDev)
	end
end

function receiveDataProtableDevices(t, m)
	--Example of topic:
	--/Environment/Controllable/TypePortable/Id/Person
	--Example of message:
	--An interaction
	local topic = t or ""
	local msg = m or ""
	local structTopic = split(topic, sepCharTopic)
	local indexDev = lua_module.searchPortableDevice(structTopic[4])
	if(indexDev)then
		tablePortableDevices[indexDev].movement = (lua_module.searchInteraction(msg) and msg or nil)
	else
		 discoveryPortableDevices(topic, msg)
		 indexDev = lua_module.searchPortableDevice(structTopic[4])
		 tablePortableDevices[indexDev].movement = (lua_module.searchInteraction(msg) and msg or nil)
	end
	updateDateTime(tablePortableDevices, indexDev)
end

function isAlivePortableDevice(mac)
	local indexDev = lua_module.searchPortableDevice(mac)
	if(indexDev)then
		tablePortableDevices[indexDev].clock = os.clock()
	end
end
-- *** End of methods to Portable Devices ***




-- *****************************************
-- ******** Methods to Post Message ********
-- *****************************************
lua_module.mqtt_lua_module = {}

local MQTT = require("mqtt_library")

function getPartialFormattedTopicSmartObject(indexObj)
	--Topic: /Environment/Controllable/Type/Id/State/StateValue
	if(indexObj == nil) then return nil end
	local obj = smartObjectsTable[indexObj]
	local topic = sepCharTopic
	topic = topic..obj.environment..sepCharTopic
	topic = topic..obj.controllable..sepCharTopic
	topic = topic..obj.type..sepCharTopic
	topic = topic..obj.mac..sepCharTopic
	return topic
end

function lua_module.mqtt_lua_module.postMessage(topic, msg)
	
	if (topic ~= nil) then
		mqtt_settings.topic_pub = topic
	end
	mqtt_settings.message = msg

	if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end

	local mqtt_client = MQTT.client.create(mqtt_settings.host, mqtt_settings.port)

	if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
	  mqtt_client:connect(mqtt_settings.id)
	else
	  mqtt_client:connect(
	    mqtt_settings.id, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message
	  )
	end

	mqtt_client:publish(mqtt_settings.topic_pub, mqtt_settings.message)

	mqtt_client:destroy()

end

function lua_module.mqtt_lua_module.postStateValue(indexObj, state, stateValue)
	if(indexObj == nil) then return end
	if(state == nil) then return end
	if(stateValue == nil) then return end

	local obj = smartObjectsTable[indexObj]

	local topic = getPartialFormattedTopicSmartObject(indexObj)
	topic = topic..state..sepCharTopic
	topic = topic..stateValue

	local msg = "State"..sepCharMsg..obj.state[state].state_value[stateValue].value..sepCharMsg..obj.state[state].state_value[stateValue].unit
	print(topic, msg)
	lua_module.mqtt_lua_module.postMessage(topic, msg)
end

function lua_module.mqtt_lua_module.postAllStateValues(indexObj, state)
	if(indexObj == nil) then return end
	if(state == nil) then return end

	local obj = smartObjectsTable[indexObj]
	for k,v in pairs(obj.state[state].state_value) do
		lua_module.mqtt_lua_module.postStateValue(indexObj, state, k)		
	end
end

function lua_module.mqtt_lua_module.postState(indexObj, state)
	lua_module.mqtt_lua_module.postAllStateValues(indexObj, state)
end

function lua_module.mqtt_lua_module.postAllStates()
	for k,v in pairs(smartObjectsTable) do
		for kS,vS in pairs(v.state) do
			lua_module.mqtt_lua_module.postState(k, kS)
		end
	end
end

function lua_module.mqtt_lua_module.postCommand(obj, functionality, command)
	-- body
end

function lua_module.mqtt_lua_module.postAllCommand(obj, functionality)
	-- body
end

function lua_module.mqtt_lua_module.postFunctionalityCOmmand(obj, functionality)
	-- body
end

function lua_module.mqtt_lua_module.postAllFunctionalityCommands()
	-- body
end

function lua_module.mqtt_lua_module.postObject(obj)
	-- body
end



-- *******************************************
-- ****** Methods to topics ******
-- *******************************************
function lua_module.getTopicsList()
  return topicsTable
end

function lua_module.addTopic(topic)
  topicsTable[#topicsTable + 1] = topic
end

function lua_module.removeTopic(topic)
  for k, v in pairs(topicsTable) do
    if (v == topic) then
      topicsTable[k] = nil
    end
  end
end


-- *****************************************
-- ***************** Main ******************
-- *****************************************
function lua_module.main(t, m)
	local topic = t or ""
	local msg = m or ""
  
  --Reserved Topics
	local switch = {
		['/discovery'] = function()
			discoverySmartObject(msg)
		end,
		['/disconnected'] = function()
			disconnectSmartObject(msg)
		end,
		['/resultquery'] = function()
			print "Test: resultaquery = ok"
		end,
		['/user_interaction/is_alive'] = function()
			print "Test: ok"
		end,
		['/user_interaction/interaction'] = function()
			print "Test: ok"
		end,
		['/test'] = function()
			print "Test: ok"
		end
	}
  
  for k, v in pairs(topicsTable) do
    switch['/discovery'..v] = function() discoverySmartObject(msg) end
    switch['/read'..v] = function() receiveDataSmartObject(msg) end
  end
  
	local f = switch[topic]

	if(f) then
		f()
	else				-- for case default
		receiveDataSmartObject(msg)
	end

end


--[[
--Metodo para teste manual
function lua_module.mainManual()
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
end]]

return lua_module

--main()
