local json = require("libs/json_lua")
local MQTT = require("libs/mqtt_library")
lanes = require "lanes".configure()

-- Tables
local smartObjectsTable = {}
local smartObjectsRequiredTable = {}
local portableDevicesTable = {}
local interactionsSupportedTable = {}

-- Global Variables 
local mqtt_client
local time_active_portable_devices = 3.0 --seconds / 10
local count_time_active_portable_devices = 0.0
local debug = false
local fileName = 'persistence.txt'

--Default topics
local TOPIC = {}
TOPIC.SMART_OBJECT_DISCOVERY    = "smart_object_discovery" -- discovery of services in smart object
TOPIC.SMART_OBJECT_READ         = "smart_object_read" -- smart object read
TOPIC.SMART_OBJECT_POST         = "smart_object" -- post smart object
TOPIC.SMART_OBJECT_DISCONNECT   = "smart_object_disconnected" -- smart object disconnected
TOPIC.QUERY_RESULT              = "query_result" -- query result
TOPIC.PORTABLE_DEVICE_RECEIVER  = "portable_device_receiver" -- receive data from portable devices
TOPIC.TEST                      = "test" -- test
TOPIC.PORTABLE_DEVICE_ALIVE     = "alive_portable_device" -- portable device alive

-- TAGs
local TAG = {}
TAG.ERROR = 'ERROR'
TAG.SUCESS = 'SUCESS'
TAG.CANCEL = 'CANCEL'
TAG.NOTFOUND = 'NOT FOUND'

-- MQTT Settings
local mqtt_settings ={
    ['host_mhubtv'] = "",
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
		o.receiveNotifications = nil
		o.receiveStates = nil
		table.insert(objs, o)
	end
	local j = {['smartobjects'] = objs,
		['portabledevices'] = portableDevicesTable}
	local file = assert(io.open(fileName, 'w'), TAG.ERROR)
	file:write(json.encode(j))
	file:flush()
	io.close(file)
end

--If is alive then it returns true, if it does not return false
function calcDiffClock(timesalved)
	--print(os.difftime (clockEnd+count_time_active_portable_devices, clockInit))
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

--Returned smart object in table
function getSmartObjectById(id)
    for k,v in pairs(smartObjectsTable) do
        --print(id..' - '..v.id)
        if(id == v.id) then
            return v
        end
    end
    return nil
end

--Returned smart objects in table
function filterByType(tab, type)
	local so = {}
	for i = 1, #tab do
		if(type == tab[i].type) then
			table.insert(so, tab[i])
		end
	end
    return so
end

function getContextDataTable()
	local file = assert(io.open(fileName, 'r'), TAG.ERROR)
	local jj = file:read("*all")
	local j = json.decode(jj)
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

function checkReceives()
	for kRequired, objRequired in pairs(smartObjectsRequiredTable) do
		for k, obj in pairs(smartObjectsTable) do
			if(objRequired.type == obj.type)then
				if(objRequired.environment)and(objRequired.environment == obj.environment)then
					smartObjectsTable[k].receiveNotifications = objRequired.receiveNotifications
					smartObjectsTable[k].receiveStates = objRequired.receiveStates
					break
				end
			end
		end
	end
end

function discoverySmartObject(obj)
    local indexObj = getIndexSmartObjectById(obj.id) --Mac - id

    if(indexObj == nil) then
        --Non-existing object
        addSmartObject(obj)
        indexObj = getIndexSmartObjectById(obj.id)
        updateDateTime(smartObjectsTable, indexObj)
        if(debug)then
           printDebug("discovery smart object:", obj.id)
        end
	    checkReceives()
    end
end

function disconnectSmartObject(id)
    local indexObj = getIndexSmartObjectById(id) -- {id}
    if (indexObj ~= nil) then
	    removeSmartObjectByIndex(indexObj)
        if(debug)then
            printDebug("disconnect smart object:", id)
        end
	    checkReceives()
    end
end

function updateSmartObject(obj)
    local indexObj = getIndexSmartObjectById(obj.id)

    if(indexObj == nil) then return end

    if(debug)then
        printDebug("read smart object:", obj.id)
    end

    local so = smartObjectsTable[indexObj]
    if (so.environment ~= obj.environment) then
        if(debug)then
            printDebug("change:", so.environment.." -> "..obj.environment)
        end
        so.environment = obj.environment
    end

    for k, v in pairs(obj.states) do
        if (so.states[k].unit ~= obj.states[k].unit) then
            if(debug)then
                printDebug("change:", so.states[k].unit.." -> "..obj.states[k].unit)
            end
            so.states[k].unit = obj.states[k].unit
        end
        if (so.states[k].value ~= obj.states[k].value) then
            if(debug)then
                printDebug("change:", so.states[k].value.." -> "..obj.states[k].value)
            end
            so.states[k].value = obj.states[k].value
        end
    end
    so.functionality = obj.functionality
	smartObjectsTable[indexObj] = so
end

function receivedDataSmartObject(obj)
    local indexObj = getIndexSmartObjectById(obj.id)
    --If non-existing smart object
    if(indexObj == nil) then
        discoverySmartObject(obj)
    else
        updateSmartObject(obj)
    end
end

function setSmartObjectsListener(t)
	if(t)then
		smartObjectsRequiredTable = t
	end
end
-- *** End of methods to Smart Objects ***

-- *************************************
-- ****** Methods to Interactions ******
-- *************************************
function getIndexSupportedInteraction(interaction)
    if(interaction == nil) then return end
    for k, inter in pairs(interactionsSupportedTable) do
        if(inter.name == interaction.name) then
            return k
        end
    end
end

-- Methods to generate events from interaction realized
function detectInteraction(device)
	local flag = false
    for i = 1, #device.interactions do
        local indexSupportedInteraction = getIndexSupportedInteraction(device.interactions[i])
        if(indexSupportedInteraction)then
            interactionsSupportedTable[indexSupportedInteraction]:detectedInteraction(device)
            if(debug)then
                printDebug("interaction detected:", device.interactions[i].name)
            end
            flag = true
        end
    end
    if(flag == nil)then
	    if(debug)then
	        printDebug(TAG.NOTFOUND, "No interaction detected:")
	    end
    end
end

function enableInteractions(bool)
	if(bool) then
        enableInteractionsOfUser = bool
	end
end

function setInteractionsListener(t)
	if(t)then
		interactionsSupportedTable = t
	end
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
    if(debug)then
        printDebug("add portable device:", device.id)
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
    local indexDev = getIndexPortableDeviceById(device.id)
    if(indexDev == nil)then return end
    portableDevicesTable[indexDev].environment = device.environment
    portableDevicesTable[indexDev].person = device.person
    portableDevicesTable[indexDev].interactions = device.interactions
    if(debug)then
        printDebug("update portable device:", device.id)
    end
end

function receivedDataPortableDevice(device)
    if(device == nil)then return end

    local indexDev = getIndexPortableDeviceById(device.id)
    if(indexDev)then
        updatePortableDevice(device)
    else
        addProtableDevice(device)
    end
    updateDateTime(portableDevicesTable, indexDev or getIndexPortableDeviceById(device.id))
	detectInteraction(device)
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
				printDebug('portable device not alive: ',v.id)
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
	local indexObj = getIndexSmartObjectById(msg.id)
	local obj = smartObjectsTable[indexObj]
	if(obj.receiveNotifications) and (obj.receiveStates)then
		obj:receiveNotifications(obj.functionality.notificationfunctionality)
		obj:receiveStates(obj.sates)
		for k, notification in pairs(obj.functionality.notificationfunctionality) do
			notification.notificationname = nil
			notification.value = nil
		end
	end
end

function topicsFilter(t, m)
    local t2 = t or ""
    if(m == nil) then return end

    local msg = json.decode(m)

    local topic = split(string.lower(t2), '/')

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
	            updateDateTime(portableDevicesTable, msg)
            end
        end,
        [TOPIC.PORTABLE_DEVICE_RECEIVER] = function()
            receivedDataPortableDevice(msg)
        end,
        [TOPIC.TEST] = function()
            print ("Test: ok, msg = "..msg)
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
function getTopics()
	local topicsTable = {}
	for k, obj in pairs(smartObjectsRequiredTable) do
		local topicsThisObj = {}
		local env = '+'
		if(obj.environment ~= nil)then
			env = obj.environment
		end
		table.insert(topicsThisObj, '/'..TOPIC.SMART_OBJECT_DISCONNECT..formatTopic(env))
		table.insert(topicsThisObj, '/'..TOPIC.SMART_OBJECT_DISCOVERY..formatTopic(env))
		table.insert(topicsThisObj, '/'..TOPIC.SMART_OBJECT_READ..formatTopic(env))

		for k, v in pairs(topicsThisObj) do
			if(obj.controllable == nil) then
				topicsThisObj[k] = topicsThisObj[k]..formatTopic('+')
			else
				topicsThisObj[k] = topicsThisObj[k]..formatTopic(obj.controllable)
			end
			if(obj.type == nil)then
				if(debug)then
					printDebug(TAG.ERROR, '[obj].type is nil')
				end
			else
				topicsThisObj[k] = topicsThisObj[k]..formatTopic(obj.type)
			end
		end
		for i = 1, #topicsThisObj do
			table.insert(topicsTable, topicsThisObj[i])
		end
	end

	if(#interactionsSupportedTable > 0)then
		table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_ALIVE..formatTopic('+'))
		table.insert(topicsTable, '/'..TOPIC.PORTABLE_DEVICE_RECEIVER..formatTopic('+'))
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
        local sleepTimer = 1.0
        socket.sleep(sleepTimer)
        if(debug)then
            printDebug("total smart object:", #smartObjectsTable)
	        if(#interactionsSupportedTable > 0)then
		        printDebug("total portable devices:", #portableDevicesTable)
		        print("")
	        end
        end
        count_time_active_portable_devices = count_time_active_portable_devices+sleepTimer/10
	    -- To check portable devices alive
		checkPortableDevicesAlive()
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
	local objJ = json.encode(obj)
	local topic = TOPIC.SMART_OBJECT_POST

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

local m_hub_tv_lua = {}
-- Settings MQTT
m_hub_tv_lua.setMqttSettings = setMqttSettings
m_hub_tv_lua.getMqttSettings = getMqttSettings

-- Methods related to Smart Objects
--lua_module.getSmartObjectsTable = getSmartObjectsTable
m_hub_tv_lua.getSmartObjectById = getSmartObjectById
m_hub_tv_lua.getSmartObjectByType = getSmartObjectByType

-- Methods related to interactions of the users and portable devices
m_hub_tv_lua.enableInteractions = enableInteractions
m_hub_tv_lua.getIndexPortableDeviceById = getIndexPortableDeviceById
--lua_module.getPortableDevicesTable = getPortableDevicesTable

-- Mode debug to LuaModule
m_hub_tv_lua.setDebug = setDebug

-- Methods LuaModule
m_hub_tv_lua.start = start
m_hub_tv_lua.stop = stop
m_hub_tv_lua.restart = restart
m_hub_tv_lua.postSmartObject = postSmartObject
m_hub_tv_lua.getContextDataTable = getContextDataTable

-- Set listeners
m_hub_tv_lua.setSmartObjectsListener = setSmartObjectsListener
m_hub_tv_lua.setInteractionsListener = setInteractionsListener

-- Remover depois é apenas para testes
--m_hub_tv_lua.postMessage = postMessage

return m_hub_tv_lua