local json = require("libs/json_lua")
local MQTT = require("libs/mqtt_library")

-- Tables
local smartObjectsTable = {}
local portableDevicesTable = {}
local interactionsTable = {}
local topicsTable = {}
local environmentsTable = {'+'}
local enableInteractionsOfUser = false

-- Global Variables 
local mqtt_client
local time_active_portable_devices = 20 --seconds

-- MQTT Settings
local mqtt_settings ={
		['host_mhubtv'] = "",
	  ['id'] = "iDTV",
	  ['port'] = 1883,
	  ['will_qos'] = 0,
	  ['will_retain'] = 0,
    ['will_topic'] = '.',
    ['keepalive'] = 3000,
    ['debug'] = true
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
function setMqttSettings(settings)
	for k,v in pairs(settings) do
		mqtt_settings[k] = v
	end
end

function getMqttSettings()
	return mqtt_settings
end

function formartTopic(str)
  if(str == nil) then return end
  local charInit = string.sub(str, 1, 1)
  local charEnd = string.sub(str, #str, #str)
  if(charInit ~= '/') then
    str = '/'..str 
  end
  if(charEnd == '/') then
    str = string.sub(str, 1, (#str-1))
  end
  return str
end


-- **************************************
-- ****** Methods to Smart Objects ******
-- **************************************
function getSmartObjectsTable()
	return smartObjectsTable
end
--Returned the index of smart object in table
function getIndexSmartObjectById(id)
	for k,v in pairs(smartObjectsTable) do
    --print(id..' - '..v.id)
		if(id == v.id) then
			return k
		end
	end
	return nil
end

--Returned the indexs of smart objects in table
function getIndexSmartObjectByType(type)
	for k,v in pairs(smartObjectsTable) do
		if(type == v.type) then
			return k
		end
	end
	return nil
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
	local indexObj = getIndexSmartObjectById(obj.id) --Mac - id

	if(indexObj == nil) then
		--Non-existing object
		addSmartObject(obj)
		indexObj = #smartObjectsTable
		updateDateTime(smartObjectsTable, indexObj)
	end
end

function disconnectSmartObject(idObj)
	--Example of msg
	--msg: id (Mac)
	local indexObj = getIndexSmartObjectById(idObj) --Mac - id
	if (indexObj ~= nil) then
		smartObjectsTable[indexObj] = nil
	end
end

function updateSmartObject(obj)
  local indexObj = getIndexSmartObjectById(obj.id)
  
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

function receivedDataSmartObject(m)
	--Example of topic
	--Topic: /Environment/Controllable/Type
  if (m == nil) then return end
	local obj = json.decode(m)
	local indexObj = getIndexSmartObjectById(obj.id)
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
function getIndexInteractionByInteractionName(interactionName)
  if(interactionName == nil) then return end
  for k, v in pairs(interactionsTable) do
    if(v[interactionName]) then
      return k
    end
  end
end

--Example of Interaction Table
--Table = {{['interactionName'] = {['description'] = '', ['action'] = function f() end}}, ...}
function setInteractionsTable(table)
	interactionsTable = table
end

function getInteractionsTable()
	return tableInteractions
end

--Ex.: interaction = {['interactionName'] = function f() end}
function addInteraction(interaction)
    interactionsTable[#interactionsTable + 1] = interaction
end

function removeInteractionByInteractionName(interactionName)
  local indexInteraction = getIndexInteractionByInteractionName(interactionName)
  if(indexInteraction)then
    interactionsTable[indexInteraction] = nil
  end
end

-- Methods to generate events from interaction realized
-- Ex.: interactionsOfUser = {'left', 'next', 'play'}
function detectInteraction(interactionsOfUser)
  local detectedInteractons = {}
  for i = 1, #interactionsOfUser do
    local indexInteraction = getIndexInteractionByInteractionName(interactionsOfUser[i])
    if(indexInteraction)then
      detectedInteractons[#detectedInteractons + 1] = interactionsOfUser[i]
      local f = interactionsTable[indexInteraction][interactionsOfUser[i]].action
      f()
    end
  end
  if(detectedInteractons)then
    return detectedInteractons
  end
end

function enableInteractions(bool)
    enableInteractionsOfUser = bool
end

-- ****** Methods to Interactions ******

-- *****************************************
-- ****** Methods to Portable Devices ******
-- *****************************************
--Returned the index of portable device in table
function getIndexPortableDeviceById(id)
	for k,v in pairs(portableDevicesTable) do
		if(id == v.id) then
			return k
		end
	end
	return nil
end

function addProtableDevice(device)
	tablePortableDevices[#tablePortableDevices + 1] = device
end

function removePortableDeviceByIndex(index)
  portableDevicesTable[index] = nil
end

function removePortableDeviceById(id)
	local indexDev = getIndexPortableDeviceById(id)
	if (indexDev) then
		removePortableDeviceByIndex(indexDev)
	end
end

function getPortableDevicesTable()
	for k,v in pairs(portableDevicesTable) do
		--If is alive
		if (calcClock(v.clock, os.clock()) == false) then
			removePortableDeviceByIndex(k)
		end
	end
	return tablePortableDevices
end

function isAlivePortableDevice(id)
  local indexDev = getIndexPortableDeviceById(id)
  if(indexDev)then
    updateDateTime(portableDevicesTable, indexDev)
  end
end

function updatePortableDevice(device)
  local indexDev = getIndexPortableDeviceById(device.id)
  if(indexDev == nil)then return end
  portableDevicesTable[indexDev].environment = device.environment
  portableDevicesTable[indexDev].person = device.environment
  portableDevicesTable[indexDev].uuid_person = device.uuid_person
  portableDevicesTable[indexDev].interactions = device.interactions
  
end

function receivedFromPortableDevice(mPortable)
    if(mPortable == nil)then return end
    local device = json.decode(mPortable)
    local indexDev = getIndexPortableDeviceById(device.id)
    if(indexDev)then
      updatePortableDevice(device)
    else
      addProtableDevice(device)
    end
    updateDateTime(portableDevicesTable, indexDev)
end


-- *** End of methods to Portable Devices ***

-- *******************************************
-- ****** Methods to topics ******
-- *******************************************
function setTopicsTable(table)
  local topics = {}
  for k, v in pairs(table) do
    topics[#topics + 1] = formartTopic(v)
  end
  topicsTable = topics
end

function getTopicsTable()
  return topicsTable
end

function addTopic(topic)
  topicsTable[#topicsTable + 1] = topic 
end

function removeTopic(topic)
  for k, v in pairs(topicsTable) do
    if (v == topic) then
      topicsTable[k] = nil
    end
  end
end

function setEnvironmentTable(table)
  local environments = {}
  for k, v in pairs(table) do
    environments[#environments + 1] = formartTopic(v)
  end
  environmentsTable = environments
end

function getEnvironment()
  return environmentsTable
end

-- *****************************************
-- ***************** Topics Filter ******************
-- *****************************************

function topicsFilter(t, m)
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
		['/portabledevice/is_alive'] = function()
			print "Test: ok"
		end,
		['/userinteraction/interaction'] = function()
			print "Test: ok"
		end,
		['/test'] = function()
			print "Test: ok"
		end
	}
  
  for kEnv, vEnv in pairs(environmentsTable) do
    for k, v in pairs(topicsTable) do
      print(vEnv..v)
      switch['/discovery'..vEnv..v] = function() discoverySmartObject(msg) end
      switch['/read'..vEnv..v] = function() receivedDataSmartObject(msg) end
    end    
    if(enableInteractionsOfUser)then
      print('/portabledevice'..vEnv..'/+')
      switch['/portabledevice'..vEnv..'/+'] = function() receivedFromPortableDevice(msg) end 
    end
  end
    
	local f = switch[topic]

	if(f) then
		f()
	else				-- for case default
		receiveDataSmartObject(msg)
	end

end


-- *****************************************
-- ******** Methods to Post Message ********
-- *****************************************
mqtt_lua_module = {}

function getPartialFormattedTopicSmartObject(indexObj)
	--Topic: /Environment/Controllable/Type/id/State/StateValue
	if(indexObj == nil) then return nil end
	local obj = smartObjectsTable[indexObj]
	local topic = sepCharTopic
	topic = topic..obj.environment..sepCharTopic
	topic = topic..obj.controllable..sepCharTopic
	topic = topic..obj.type..sepCharTopic
	topic = topic..obj.mac..sepCharTopic
	return topic
end

function mqtt_lua_module.postMessage(topic, msg)
	
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

function mqtt_lua_module.postStateValue(indexObj, state, stateValue)
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

function mqtt_lua_module.postAllStateValues(indexObj, state)
	if(indexObj == nil) then return end
	if(state == nil) then return end

	local obj = smartObjectsTable[indexObj]
	for k,v in pairs(obj.state[state].state_value) do
		lua_module.mqtt_lua_module.postStateValue(indexObj, state, k)		
	end
end

function mqtt_lua_module.postState(indexObj, state)
	lua_module.mqtt_lua_module.postAllStateValues(indexObj, state)
end

function mqtt_lua_module.postAllStates()
	for k,v in pairs(smartObjectsTable) do
		for kS,vS in pairs(v.state) do
			lua_module.mqtt_lua_module.postState(k, kS)
		end
	end
end

function mqtt_lua_module.postCommand(obj, functionality, command)
	-- body
end

function mqtt_lua_module.postAllCommand(obj, functionality)
	-- body
end

function mqtt_lua_module.postFunctionalityCOmmand(obj, functionality)
	-- body
end

function mqtt_lua_module.postAllFunctionalityCommands()
	-- body
end

function mqtt_lua_module.postObject(obj)
	-- body
end



function subscribeAllTopics()
  if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end

  if (mqtt_settings.keepalive) then MQTT.client.KEEP_ALIVE_TIME = mqtt_settings.keepalive end

  mqtt_client = MQTT.client.create(mqtt_settings.host_mhubtv, mqtt_settings.port, topicsFilter)

  if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
    mqtt_client:connect(mqtt_settings.id)
  else
      mqtt_client:connect(mqtt_settings.id, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message)
  end

  mqtt_client:subscribe(topicsTable)

  local error_message = nil
  while (error_message == nil) do
    error_message = mqtt_client:handler()
    socket.sleep(1.0) 
  end

  if (error_message == nil) then
    mqtt_client:unsubscribe(topicsTable)
    mqtt_client:destroy()
  else
    print(error_message)
  end
end

function unsubscribeAllTopics()
  if(mqtt_client) then
    mqtt_client:unsubscribe(topicsTable)
  end
end

function refreshSubscribes()
    lua_module.unsubscribeAllTopics()
    lua_module.subscribeAllTopics()
end

local lua_module = {}
lua_module.setMqttSettings = setMqttSettings
lua_module.getMqttSettings = getMqttSettings

lua_module.getSmartObjectsTable = getSmartObjectsTable
lua_module.getIndexSmartObjectById = getIndexSmartObjectById
lua_module.getIndexSmartObjectByType = getIndexSmartObjectByType

lua_module.setInteractionsTable = setInteractionsTable
lua_module.getInteracionsTable = getInteracionsTable
lua_module.addInteraction = addInteraction
lua_module.getIndexInteractionByInteractionName = getIndexInteractionByInteractionName
lua_module.removeInteractionByInteractionName = removeInteractionByInteractionName
lua_module.detectInteraction = detectInteraction
lua_module.enableInteractions = enableInteractions

lua_module.getIndexPortableDeviceById = getIndexPortableDeviceById
lua_module.getPortableDevicesTable = getPortableDevicesTable

lua_module.setEnvironmentTable = setEnvironmentTable
lua_module.getEnvironmentTable = getEnvironmentTable

lua_module.setTopicsTable = setTopicsTable
lua_module.getTopicsTable = getTopicsTable
lua_module.addTopic = addTopic
lua_module.removeTopic = removeTopic

lua_module.subscribeAllTopics = subscribeAllTopics
lua_module.unsubscribeAllTopics = unsubscribeAllTopics
lua_module.refreshSubscribes = refreshSubscribes

lua_module.mqtt_lua_module = mqtt_lua_module


--test | remover depois
lua_module.topicsFilter = topicsFilter

return lua_module













