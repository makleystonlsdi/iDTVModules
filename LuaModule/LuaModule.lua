
-- Tables
local tableSmartObjects = {}
local tablePortableDevices = {}

-- Global variables
local sepCharTopic = "/"
local sepCharMsg = "&";

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

function searchSmartObject(obj)
	for i=1,#tableSmartObject do
		if(obj.mac == tableSmartObject[i].mac) then
			return obj
		end
		return
	end
end

function updateState(structTopic, structMsg)
	local obj = {
		['mac'] = structTopic[4],
		['environment'] = structTopic[1],
		['controllable'] = structTopic[2],
		['type'] = structTopic[3],
		['state'] = structTopic[5],
		['state_value'] = structTopic[6],
		['value'] = structMsg[1],
		['unit'] = structMsg[2],
	}
	tableSmartObjects[#tableSmartObjects + 1] = obj
end

function updateFunctionalityNotification(structTopic, structMsg)
	local obj = {
		['mac'] = structTopic[4],
		['environment'] = structTopic[1],
		['controllable'] = structTopic[2],
		['type'] = structTopic[3],
		['functionality'] = structTopic[5],
		['notification'] = structTopic[6],
		['notification_name'] = structMsg[1],
	}
end

function updateFunctionalityCommand(structTopic, structMsg)
	local obj = {
		['mac'] = structTopic[4],
		['environment'] = structTopic[1],
		['controllable'] = structTopic[2],
		['type'] = structTopic[3],
		['functionality'] = structTopic[5],
		['command'] = structTopic[6],
		['command_name'] = structMsg[1],
	}
end


function updateProtableDevces(...)
	-- body
end

function function_name(...)
	-- body
end

function updateSmartObject(t, m)
	--Topic: /Environment/Controllable/Type/Id/State/StateValue
	--Topic: /Environment/Controllable/Type/Id/Functionality/Notification
	--Topic: /Environment/Controllable/Type/Id/Functionality/Command
	local topic =  t or ""
	local msg = m or ""

	local structTopic = split(topic, sepCharTopic)
	local structMsg = split(msg, sepCharMsg)
	if(structMsg[1] == "State") then
		updateState(structTopic, structMsg)
	else if (structMsg[1] == "Functionality") then

	end
end