local json = require("libs/json_lua")
local MQTT = require("libs/mqtt_library")

-- Tables
local smartObjectsTable = {}
local portableDevicesTable = {}
local interactionsTable = {}
local topicsTable = {}
local topicsTableEdit = {}
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
    ['debug'] = false
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

function print_style(str)
  local size = string.len(str)
  local ch = ""
  for i=1, size*2 do
    ch = ch.."*"
  end
  local mid = size/2
  local chc = ""
  if(math.fmod(size, 2)==0)then
    mid = mid-1
  end
  for i=1, mid do
    chc = chc.." "
  end
  local s = "*"..chc..str..chc.."*"
  print(ch)
  print(s)
  print(ch)
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

function formatTopic(str)
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
  table.insert(smartObjectsTable, obj)
end

function removeSmartObject(index)
	table.remove(smartObjectsTable, index)
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
    table.remove(smartObjectsTable, indexObj)
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
  --print(obj.id, obj.states.color_state.value)
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
  table.insert(interactionsTable, interaction)
end

function removeInteractionByInteractionName(interactionName)
  local indexInteraction = getIndexInteractionByInteractionName(interactionName)
  if(indexInteraction)then
    table.remove(interactionsTable, indexInteraction)
  end
end

-- Methods to generate events from interaction realized
-- Ex.: interactionsOfUser = {'left', 'next', 'play'}
function detectInteraction(interactionsOfUser)
  local detectedInteractons = {}
  for i = 1, #interactionsOfUser do
    local indexInteraction = getIndexInteractionByInteractionName(interactionsOfUser[i])
    if(indexInteraction)then
      table.insert(detectedInteractons, interactionsOfUser[i])
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
  table.insert(portableDevicesTable, device)
end

function removePortableDeviceByIndex(index)
  table.remove(portableDevicesTable, index)
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
		if (calcDiffClock(v.clock, os.clock()) == false) then
			removePortableDeviceByIndex(k)
		end
	end
	return portableDevicesTable
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
  --person = {['attr'] = 'value'}
  portableDevicesTable[indexDev].person = device.person
  portableDevicesTable[indexDev].uuid_person = device.uuid_person
  portableDevicesTable[indexDev].interactions = device.interactions
  --print(portableDevicesTable[indexDev].person.name)
end

function receivedDataPortableDevice(mPortable)
    if(mPortable == nil)then return end
    local device = json.decode(mPortable)
    local indexDev = getIndexPortableDeviceById(device.id)
    if(indexDev)then
      updatePortableDevice(device)
    else
      addProtableDevice(device)
    end
    updateDateTime(portableDevicesTable, indexDev or #portableDevicesTable)
end

-- *** End of methods to Portable Devices ***

-- *******************************************
-- ****** Methods to topics ******
-- *******************************************
function setTopicsTable(table)
  local topics = {}
  for k, v in pairs(table) do
    table.insert(topics, formatTopic(v))
  end
  topicsTable = topics
end

function getTopicsTable()
  return topicsTable
end

function addTopic(topic)
  table.insert(topicsTable, formatTopic(topic))
end

function removeTopic(topic)
  for k, v in pairs(topicsTable) do
    if (v == topic) then
      table.remove(topicsTable, k)
    end
  end
end

function setEnvironmentTable(environmentTable)
  local environments = {}
  for k, v in pairs(environmentTable) do
    table.insert(environments, formatTopic(v))
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
	local t2 = t or ""
	local msg = m or ""
  
  local topic = split(t2, '/')
  
  --Topics
	local switch = {
		['smart_object_discovery'] = function()
			discoverySmartObject(msg)
		end,
    ['smart_object_read'] = function()
      receivedDataSmartObject(msg)
		end,
		['smart_object_disconnected'] = function()
			disconnectSmartObject(msg)
		end,
		['query_result'] = function()
			print "Test: resultaquery = ok"
		end,
		['alive_portable_device'] = function()
			print ("is alive: id = "..m)
		end,
    ['portable_device'] = function()
			receivedDataPortableDevice(msg)
		end,
		['test'] = function()
			print ("Test: ok, msg = "..msg)
		end
	}
  
	local f = switch[topic[1]]

	if(f) then
		f()
	else				-- for case default
    --print(msg)
		receivedDataSmartObject(msg)
	end

end

-- *****************************************
-- ******** Methods to Post Message ********
-- *****************************************
mqtt_lua_module = {}

function mqtt_lua_module.postMessage(topic, msg)
	if(msg == nil)then return end
	if(t == nil)then return end
  
  local topic = t or "/test"

	if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end
  
	local mqtt_client = MQTT.client.create(mqtt_settings.host_mhubtv, mqtt_settings.port)

	if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
	  mqtt_client:connect(mqtt_settings.id)
	else
	  mqtt_client:connect(
	    mqtt_settings.id, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message
	  )
	end

	mqtt_client:publish(topic, msg)

	mqtt_client:destroy()
end

function mqtt_lua_module.postSmartObject(obj)
	if(obj == nil)then return end
  local objJ = json.encode(obj)
  local topic = "/smart_object"

	if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end
  
	local mqtt_client = MQTT.client.create(mqtt_settings.host_mhubtv, mqtt_settings.port)

	if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
	  mqtt_client:connect(mqtt_settings.id)
	else
	  mqtt_client:connect(
	    mqtt_settings.id, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message
	  )
	end

	mqtt_client:publish(topic, objJ)
	mqtt_client:destroy()
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
  
  topicsTableEdit = {}
  for k,v in pairs(environmentsTable)do
    for kt, vt in pairs(topicsTable)do
      local t = formatTopic(v)
      t = t .. formatTopic(vt)
      table.insert(topicsTableEdit, formatTopic("smart_object_discovery")..t)
      table.insert(topicsTableEdit, formatTopic("smart_object_read")..t)
    end
  end

  mqtt_client:subscribe(topicsTableEdit)

  local error_message = nilform
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
    mqtt_client:unsubscribe(topicsTableEdit)
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