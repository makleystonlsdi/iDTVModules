local json = require("libs/json_lua")
local MQTT = require("libs/mqtt_library")

-- Tables
local smartObjectsTable = {}
local smartObjectsRequiredTable = {}
local portableDevicesTable = {}
local environmentsTable = {}
events = nil
kill = false

-- Global Variables
local mqtt_client
local time_active_portable_devices = 3.0 --seconds / 10
local count_time_active_portable_devices = 0.0
local debug = false
local epg = {}
local fileName = 'persistence.txt'
local applicationName = 'iDTVApplication'
local applicationId = applicationName..math.random(os.time())..math.random(os.time())

--Default topics
local TOPIC = {}
TOPIC.SMART_OBJECT_DISCOVERY    = "smart_object_discovery" -- discovery of services in smart object
TOPIC.SMART_OBJECT_REQUEST      = "smart_object_request" -- request of services in smart object
TOPIC.SMART_OBJECT_READ         = "smart_object_read" -- smart object read
TOPIC.SMART_OBJECT_POST         = "smart_object" -- post smart object
TOPIC.SMART_OBJECT_DISCONNECT   = "smart_object_disconnected" -- smart object disconnected
TOPIC.QUERY_RESULT              = "query_result" -- query result
TOPIC.PORTABLE_DEVICE_RECEIVER  = "portable_device_receiver" -- receive data from portable devices
TOPIC.TEST                      = "test" -- test
TOPIC.PORTABLE_DEVICE_ALIVE     = "alive_portable_device" -- portable device alive
TOPIC.GET_PARAMS_IDTV_APPLICATION         = "get_system_params" -- The M-Hub-TV request the parameters of the system
TOPIC.RESULT_SYSTEM_PARAMS      = "result_system_params" -- The M-Hub-TV request the parameters of the system

-- Global TAGs
local TAG = {}
TAG.ERROR = 'ERROR'
TAG.SUCESS = 'SUCESS'
TAG.CANCEL = 'CANCEL'
TAG.NOTFOUND = 'NOT FOUND'

-- MQTT Settings
local mqtt_settings ={
	['host_master'] = "",
	['id'] = "iDTV"..math.random(os.time())..math.random(os.time()),
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

function setDebug(bool)
	if(bool)then
		debug = bool
	end
end

function printDebug(tag, str)
	print(tag, str)
end

function updateDateTime(tab, indexObj)
	local clock = os.clock()
	tab[indexObj].clock = clock
	tab[indexObj].time = count_time_active_portable_devices
end

function clone(o)
	if (type(o)~="table") then
		return o
	else
		local new_o ={}
		for i,v in pairs(o) do
			new_o[i] = clone(v)
		end
		return new_o
	end
end

function persistence()
	local objs = {}
	for k, v in pairs(smartObjectsTable) do
		local o = clone(v)
		o.receiveNotification = nil
		o.filterByType = nil
		--o.receiveState = nil
		table.insert(objs, o)
	end
	local j = {['smartobjects'] = objs,
		['portabledevices'] = portableDevicesTable,
		['time'] = os.time()}
	local file = assert(io.open(fileName, 'w'), TAG.ERROR)
	file:write(json.encode(j))
	file:flush()
	io.close(file)
end

--If is alive then it returns true, if it does not return false
function calcDiffClock(timesalved)
	if(count_time_active_portable_devices-timesalved <= time_active_portable_devices) then
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

function setEPG(e)
	for k,v in pairs(e) do
		epg[k] = v
	end
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
-- ****** end *****

-- ********************
function setEnvironmentsDefault(env)
	if(env)then
		environmentsTable = env
	end
end

-- *******************


-- **************************************
-- ****** Methods to Smart Objects ******
-- **************************************
--Returned the index of smart object in table
function getIndexSmartObject(id, type)
	if(type == nil)then --if smart object diconnected
		for k,v in pairs(smartObjectsTable) do
			if(""..id == ""..v.Id) then
				return k
			end
		end
	else -- default
		for k,v in pairs(smartObjectsTable) do
			if(id == v.Id) and (type == v.Type) then
				return k
			end
		end
	end
	return nil
end

--Returned the indexs of smart objects in table
function getIndexSmartObjectByType(type)
	for k,v in pairs(smartObjectsTable) do
		if(type == v.Type) then
			return k
		end
	end
	return nil
end

--Returned smart object in table
function getSmartObjectById(id)
	for k,v in pairs(smartObjectsTable) do
		if(id == v.Id) then
			return v
		end
	end
	return nil
end

function getSmartObjectsTable()
	return smartObjectsTable
end

--Returned smart objects in table
function filterByType(tab, type)
	local so = {}
	for i = 1, #tab do
		if(type == tab[i].Type) then
			table.insert(so, tab[i])
		end
	end
	return so
end

function getContextDataTable()
	local file = assert(io.open(fileName, 'r'), TAG.ERROR)
	local jj = file:read("*all")
	local j = json.decode(jj)
	--print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& "..j.time)
	--if((os.time() - j.time) < 5)then
	if(j.smartobjects)then
		j.smartobjects.filterByType = filterByType
	end
	return j

end

function addSmartObject(obj)
	table.insert(smartObjectsTable, obj)
end

function removeSmartObjectByIndex(index)
	table.remove(smartObjectsTable, index)
end

function checkReceives2()
	for kRequired, objRequired in pairs(smartObjectsRequiredTable) do
		for k, obj in pairs(smartObjectsTable) do
			if(objRequired.Type == obj.Type)then
				if(objRequired.Environment == nil)then
					smartObjectsTable[k].receiveNotification = objRequired.receiveNotification
					break
				elseif(objRequired.Environment)and(objRequired.Environment == obj.Environment)then
					smartObjectsTable[k].receiveNotification = objRequired.receiveNotification
					--smartObjectsTable[k].receiveState = objRequired.receivestate
					break
				end
			end
		end
	end
end

function checkReceives(indexObj)
	if(#smartObjectsTable == 0)then return end
	for kRequired, objRequired in pairs(smartObjectsRequiredTable) do
		if(objRequired.Type == smartObjectsTable[indexObj].Type)then
			local ids = {}
			for k, obj in pairs(smartObjectsTable) do
				if(obj.Type == objRequired.Type)then
					if(objRequired.Environment == nil)or((objRequired.Environment)and(objRequired.Environment == obj.Environment))then
						table.insert(ids, k)
					end
				end
			end
			if(#ids >0)then
				local flagSO
				for i = 1, #ids do
					if(smartObjectsTable[ids[i]].receiveNotification)then
						flagSO = true
						break
					end
				end
				if(flagSO == nil)then
					smartObjectsTable[ids[1]].receiveNotification = objRequired.receiveNotification
				end

				--verificar se já tem o receiveNotification
				local currentSos = {}
				for i = 1, #ids do
					table.insert(currentSos, smartObjectsTable[ids[i]])
				end
				smartObjectSwitch:smartObjectSwitch(currentSos, smartObjectsTable[indexObj])
			end
		end
	end
end

function checkReceives3(indexObj)
	if(#smartObjectsRequiredTable == 0)then return end
	for kRequired, objRequired in pairs(smartObjectsRequiredTable) do
		local ids = {}
		local idsEnv = {}
		local firstID
		for k, obj in pairs(smartObjectsTable) do
			if(objRequired.Type == obj.Type)then
				if(objRequired.Environment == nil)then
					if(firstID==nil)then
						firstID = k
					end
					if(obj.receiveNotification)then
						table.insert(ids, k)
					end
				elseif(objRequired.Environment == obj.Environment)then
					if(firstID==nil)then
						firstID = k
					end
					if(obj.receiveNotification)then
						table.insert(idsEnv, k)
					end
				end

			end
		end

		if(objRequired.Environment == nil)then
			if(#ids == 0)then
				smartObjectsTable[firstID].receiveNotification = objRequired.receiveNotification
			else
				local currentSos = {}
				for i = 1, #ids do
					table.insert(currentSos, smartObjectsTable[ids[i]])
				end
				smartObjectSwitch:smartObjectSwitch(currentSos, smartObjectsTable[indexObj])
			end
		else
			if(#idsEnv == 0)then
				smartObjectsTable[firstID].receiveNotification = objRequired.receiveNotification
			else
				local currentSos = {}
				for i = 1, #idsEnv do
					table.insert(currentSos, smartObjectsTable[idsEnv[i]])
				end
				smartObjectSwitch:smartObjectSwitch(currentSos, smartObjectsTable[indexObj])
			end
		end
	end
end

function discoverySmartObject(obj)
	local indexObj = getIndexSmartObject(obj.Id, obj.Type) --Mac - id

	if(indexObj == nil) then
		--Non-existing object
		obj.filterByType = filterByType
		addSmartObject(obj)
		indexObj = getIndexSmartObject(obj.Id, obj.Type)
		updateDateTime(smartObjectsTable, indexObj)
		if(debug)then
			printDebug("discovery smart object:", "Id:"..obj.Id..", Type: "..obj.Type)
		end
		checkReceives(indexObj)
	end
end

function disconnectSmartObject(id)
	local indexObj = getIndexSmartObject(id, nil) -- {id}
	if (indexObj ~= nil) then
		removeSmartObjectByIndex(indexObj)
		if(debug)then
			printDebug("disconnect smart object:", id)
		end
		checkReceives(indexObj)
	end
end

function updateSmartObject(obj)
	local indexObj = getIndexSmartObject(obj.Id, obj.Type)

	if(indexObj == nil) then return end

	if(debug)then
		printDebug("read smart object:", obj.Id)
	end

	local so = smartObjectsTable[indexObj]
	if (so.Environment ~= obj.Environment) then
		if(debug)then
			printDebug("change:", so.Environment.." -> "..obj.Environment)
		end
		so.Environment = obj.Environment
	end

	for k, v in pairs(obj.State) do
		if (so.State[k].unit ~= obj.State[k].unit) then
			if(debug)then
				printDebug("change:", so.State[k].unit.." -> "..obj.State[k].unit)
			end
			so.State[k].unit = obj.State[k].unit
		end
		if (so.State[k].value ~= obj.State[k].value) then
			if(debug)then
				printDebug("change:", so.State[k].value.." -> "..obj.State[k].value)
			end
			so.State[k].value = obj.State[k].value
		end
	end
	so.Functionality = obj.Functionality
	smartObjectsTable[indexObj] = so
end

function receivedDataSmartObject(obj)
	local indexObj = getIndexSmartObject(obj.Id, obj.Type)
	--If non-existing smart object
	if(indexObj == nil) then
		discoverySmartObject(obj)
	else
		updateSmartObject(obj)
	end
end

function setSmartObjectsListener(t, c)
	if(t)then
		smartObjectsRequiredTable = t
	end
	if(c)then
		smartObjectSwitch = c
	end
end
-- *** End of methods to Smart Objects ***

-- *************************************
-- ****** Methods to Events ******
-- *************************************
-- Methods to generate events from interaction realized
function detectEvents(device)
	if(events == nil)then
		if(debug)then
			printDebug(TAG.ERROR, "Not event defined!")
		end
		return
	end

	if(device.Events)then
		if(#device.Events>0)then
			events:receiveEvents(device, device.Events)
		end
		if(debug)then
			if(#device.Events > 0)then
				printDebug(TAG.SUCESS, "Interaction detected. Total "..#device.Events)
			else
				--  printDebug(TAG.NOTFOUND, "No interaction detected")
			end
		end
	end
end

function setEventsListener(evt)
	if(evt)then
		events = evt
	end
end
-- ****** Methods to Interactions ******

-- *****************************************
-- ****** Methods to Portable Devices ******
-- *****************************************
--Returned the index of portable device in table
function getIndexPortableDeviceById(id)
	for k,v in pairs(portableDevicesTable) do
		if(id == v.Id) then
			return k
		end
	end
	return nil
end

function addProtableDevice(device)
	table.insert(portableDevicesTable, device)
	if(debug)then
		printDebug("add portable device:", device.Id)
	end
end

function removePortableDeviceByIndex(index)
	table.remove(portableDevicesTable, index)
end

function removePortableDeviceById(id)
	local indexDev = getIndexPortableDeviceById(id)
	if (indexDev) then
		removePortableDeviceByIndex(indexDev)
		if(debug)then
			printDebug("remove portable device:", id)
		end
	end
end

function getPortableDevicesTable()
	return portableDevicesTable
end

function isAlivePortableDevice(id)
	local indexDev = getIndexPortableDeviceById(id)
	if(indexDev)then
		updateDateTime(portableDevicesTable, indexDev)
	end
end

function updatePortableDevice(device)
	local indexDev = getIndexPortableDeviceById(device.Id)
	if(indexDev == nil)then return end
	portableDevicesTable[indexDev].Environment = device.Environment
	portableDevicesTable[indexDev].Person = device.Person
	portableDevicesTable[indexDev].Events = device.Events
	if(debug)then
		--printDebug("update portable device:", device.Id)
	end
end

function receivedDataPortableDevice(device)
	if(device == nil)then return end

	local indexDev = getIndexPortableDeviceById(device.Id)
	if(indexDev)then
		updatePortableDevice(device)
	else
		addProtableDevice(device)
	end
	updateDateTime(portableDevicesTable, indexDev or getIndexPortableDeviceById(device.Id))
	detectEvents(device)
end

function setAliveTimePortableDevice(time)
	if(time)then
		time_active_portable_devices = time / 10
	end
end

function checkPortableDevicesAlive()
	for k,v in pairs(portableDevicesTable) do
		--If is alive
		if (calcDiffClock(v.time) == false) then
			if(debug)then
				printDebug('portable device not alive: ',v.Id)
			end
			removePortableDeviceByIndex(k)
			persistence()
		end
	end
end
-- *** End of methods to Portable Devices ***

-- *****************************************
-- ***************** Topics Filter *********
-- *****************************************
function smartObjectListiner(msg)
	local indexObj = getIndexSmartObject(msg.Id, msg.Type)
	local obj = smartObjectsTable[indexObj]
	if(obj.receiveNotification)then
		if(obj.Functionality.NotificationFunctionality)then
			obj:receiveNotification(obj.Functionality.NotificationFunctionality)
		end
	end
end

function topicsFilter(t, m)
	local t2 = t or ""

	if(m == nil) then return end

	local msg = json.decode(m)

	local topic = split(t2, '/')

	if(debug)then
		printDebug("Topic: ", topic[1])
	end
	--Topics
	local switch = {
		[TOPIC.SMART_OBJECT_DISCOVERY] = function()
			discoverySmartObject(msg)
		end,
		[TOPIC.SMART_OBJECT_READ] = function()
			receivedDataSmartObject(msg)
			smartObjectListiner(msg)
		end,
		[TOPIC.SMART_OBJECT_DISCONNECT] = function()
			disconnectSmartObject(msg)
		end,
		[TOPIC.QUERY_RESULT] = function()
			print "Test: resultaquery = ok"
		end,
		[TOPIC.PORTABLE_DEVICE_ALIVE] = function()
			if(msg)then
				local indexDevice = getIndexPortableDeviceById(msg.id)
				if(indexDevice)then
					updateDateTime(portableDevicesTable, indexDevice)
				else
					receivedDataPortableDevice(msg)
				end
			end
		end,
		[TOPIC.PORTABLE_DEVICE_RECEIVER] = function()
			receivedDataPortableDevice(msg)
		end,
		[TOPIC.TEST] = function()
			print ("Test: ok, msg = "..msg)
		end,
		[TOPIC.GET_PARAMS_IDTV_APPLICATION] = function()
			if(msg)then
				getSystemParams(msg)
			end
		end
	}

	local f = switch[topic[1]]

	if(f) then
		f()
	end
	persistence()

end
-- **************** end **********

-- ********** Topics ************
function checkTopic(env)
	if(env == nil)then return false end

	for i = 1, #environmentsTable do
		if(environmentsTable[i] == env)then
			return true
		end
	end

	return false
end

function getTopics()
	local topicsTable = {}
	-- topics of the actuators
	local envTmp = '+'
	if(#environmentsTable>0)then
		for k, e in pairs(environmentsTable) do
			table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(e)..formatTopic('Actuator')..formatTopic('+'))
			table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(e)..formatTopic('Actuator')..formatTopic('+'))
			table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(e)..formatTopic('Actuator')..formatTopic('+'))
			table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_ALIVE..formatTopic(e))
			table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_RECEIVER..formatTopic(e))
		end
	else
		table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(envTmp)..formatTopic('Actuator')..formatTopic('+'))
		table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(envTmp)..formatTopic('Actuator')..formatTopic('+'))
		table.insert(topicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(envTmp)..formatTopic('Actuator')..formatTopic('+'))
		table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_ALIVE..formatTopic(envTmp))
		table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_RECEIVER..formatTopic(envTmp))
	end

	-- functionalities topics
	table.insert(topicsTable, '/'..TOPIC.GET_PARAMS_IDTV_APPLICATION)
	table.insert(topicsTable, '/'..TOPIC.QUERY_RESULT)

	for k, obj in pairs(smartObjectsRequiredTable) do
		envTmp = '+'
		local sensorsTopicsTable = {}
		if(#environmentsTable>0)then
			for k, e in pairs(environmentsTable) do
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(e)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(e)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(e)..formatTopic('Sensor'))
			end
			if(obj.Environment ~= nil) and (checkTopic(obj.Environment) == false) then
				envTmp = obj.Environment
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(envTmp)..formatTopic('Sensor'))
			end
		else
			if(obj.Environment ~= nil) then
				envTmp = obj.Environment
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(envTmp)..formatTopic('Sensor'))
			elseif(obj.Environment == nil)then
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(envTmp)..formatTopic('Sensor'))
				table.insert(sensorsTopicsTable, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(envTmp)..formatTopic('Sensor'))
			end
		end

		for k, v in pairs(sensorsTopicsTable) do
			if(obj.Type == nil)then
				if(debug)then
					printDebug(TAG.ERROR, '[obj].Type is nil')
				end
			else
				sensorsTopicsTable[k] = sensorsTopicsTable[k]..formatTopic(obj.Type)
			end
		end
		for i = 1, #sensorsTopicsTable do
			table.insert(topicsTable, sensorsTopicsTable[i])
		end
	end

	return topicsTable
end
-- ********** End ***************

-- *****************************************
-- ******** Methods to Post Message ********
-- *****************************************
local mqtt_lua_module = {}

function mqtt_lua_module:post(topic, msg)
	if(msg == nil)then return end
	local objJ = json.encode(msg)

	if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end

	local var = math.random(os.time())
	local mqtt_client = MQTT.client.create(mqtt_settings.host_mhubtv, mqtt_settings.port)

	if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
		mqtt_client:connect(mqtt_settings.id..var)
	else
		mqtt_client:connect(
			mqtt_settings.id..var, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message
		)
	end

	mqtt_client:publish(topic, objJ)
	mqtt_client:destroy()
end

function mqtt_lua_module:subscribe()
	if (mqtt_settings.debug) then MQTT.Utility.set_debug(true) end

	if (mqtt_settings.keepalive) then MQTT.client.KEEP_ALIVE_TIME = mqtt_settings.keepalive end

	mqtt_client = MQTT.client.create(mqtt_settings.host_mhubtv, mqtt_settings.port, topicsFilter)

	if (mqtt_settings.will_message == "."  or  mqtt_settings.will_topic == ".") then
		mqtt_client:connect(mqtt_settings.id)
	else
		mqtt_client:connect(mqtt_settings.id, mqtt_settings.will_topic, mqtt_settings.will_qos, mqtt_settings.will_retain, mqtt_settings.will_message)
	end

	local topics = getTopics()

	if(debug)then
		if(#topics == 0)then
			printDebug("subscribed topic: ", 'nil')
		else
			for k,v in pairs(topics) do
				printDebug("subscribed topic: ", v)
			end
		end
	end

	mqtt_client:subscribe(topics)

	local error_message
	while (error_message == nil) do
		error_message = mqtt_client:handler()

		if(first == nil)then
			postMessage(formatTopic(TOPIC.SMART_OBJECT_REQUEST), "true")
			first = true
		end

		local sleepTimer = 1.0
		socket.sleep(sleepTimer)
		if(debug)then
			printDebug("total smart object:", #smartObjectsTable)
			if(events)then
				printDebug("total portable devices:", #portableDevicesTable)
				print("")
			end
		end
		count_time_active_portable_devices = count_time_active_portable_devices+sleepTimer/10
		-- To check portable devices alive
		checkPortableDevicesAlive()
		--persistence()
		if(kill)then
			error_message = true
			kill = false
		end
	end

	if (error_message == nil) then
		mqtt_client:unsubscribe(topics)
		mqtt_client:destroy()
	else
		print(error_message)
	end
end

function mqtt_lua_module:unsubscribe()
	if(mqtt_client) then
		mqtt_client:unsubscribe(topicsTableEdit)
	end
end

function mqtt_lua_module:refreshSubscribes()
	lua_module.mqtt_lua_module:unsubscribe()
	lua_module.mqtt_lua_module:subscribe()
end

function start()
	mqtt_lua_module:subscribe()
end

function killEventGinga(f)
	kill = f
end

function stop()
	mqtt_lua_module:unsubscribeAllTopics()
end

function restart()
	mqtt_lua_module:refreshSubscribes()
end

function postMessage(t, msg)
	if(msg == nil)then return end
	local topic = t or "/test"

	mqtt_lua_module:post(topic, msg)
end

function postSmartObject(obj)
	if(obj == nil)then return end
	local o = clone(obj);
	o.Functionality.NotificationFunctionality = nil
	o.State = nil
	local objJ = json.encode(o)
	--print(objJ)
	local topic = formatTopic(TOPIC.SMART_OBJECT_POST)

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

getSystemParams = function(id)
	local params = {}
	params.requester = id
	params.applicationName = applicationName
	params.appId = appId

	postMessage(formatTopic(TOPIC.RESULT_SYSTEM_PARAMS), params)
end

function setApplicationName(appName)
	applicationName = appName
end

local CASMOC = {}
-- Settings MQTT
CASMOC.setMqttSettings = setMqttSettings
CASMOC.getMqttSettings = getMqttSettings

-- Methods related to Smart Objects
CASMOC.getSmartObjectsTable = getSmartObjectsTable
CASMOC.getSmartObjectById = getSmartObjectById
CASMOC.getSmartObjectByType = getSmartObjectByType

-- Methods related to interactions of the users and portable devices
CASMOC.getIndexPortableDeviceById = getIndexPortableDeviceById
CASMOC.getPortableDevicesTable = getPortableDevicesTable

-- Mode debug to LuaModule
CASMOC.setDebug = setDebug

CASMOC.setEPG = setEPG

-- Methods LuaModule
CASMOC.start = start
CASMOC.stop = stop
CASMOC.restart = restart
CASMOC.postSmartObject = postSmartObject
CASMOC.getContextDataTable = getContextDataTable
CASMOC.getSystemParams = getSystemParams
CASMOC.setApplicationName = setApplicationName
CASMOC.setEnvironmentsDefault = setEnvironmentsDefault

-- Set listeners
CASMOC.setSmartObjectsListener = setSmartObjectsListener
CASMOC.setEventsListener = setEventsListener

-- Remover depois é apenas para testes
CASMOC.postMessage = postMessage
CASMOC.killEventGinga = killEventGinga
--m_hub_tv_lua.getTopics = getTopics

return CASMOC