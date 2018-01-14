-- Imports
package.path = package.path .. ";../libs/?.lua"

function callback(
  topic,    -- string
  message)  -- string
   	print("Topic: " .. topic .. ", message: '" .. message .. "'")
end

local args =  {
	  ['host'] = 'localhost',
	  ['id'] = 'mqtt_tv',
	  ['message'] = '',
	  ['port'] = 1883,
	  ['topic'] = '/#',
	  ['will_message'] = '.',
	  ['will_qos'] = 0,
	  ['will_retain'] = 0,
	  ['will_topic'] = '.',
    ['keepalive'] = 3000,
    ['debug'] = true
	}
 
local MQTT = require("mqtt_library")

if (args.debug) then MQTT.Utility.set_debug(true) end

if (args.keepalive) then MQTT.client.KEEP_ALIVE_TIME = args.keepalive end

local mqtt_client = MQTT.client.create(args.host, args.port, callback)

if (args.will_message == "."  or  args.will_topic == ".") then
	mqtt_client:connect(args.id)
else
  	mqtt_client:connect(args.id, args.will_topic, args.will_qos, args.will_retain, args.will_message)
end

mqtt_client:subscribe({'/a','/b','/c'})

local error_message = nil

while (error_message == nil) do
  error_message = mqtt_client:handler()
  socket.sleep(1.0) 
end

if (error_message == nil) then
  mqtt_client:unsubscribe({args.topic})
  mqtt_client:destroy()
else
  print(error_message)
end