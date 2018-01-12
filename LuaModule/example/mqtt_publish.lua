-- ------------------------------------------------------------------------- --
-- mqtt_publish.lua
-- ~~~~~~~~~~~~~~~~
-- Please do not remove the following notices.
-- Copyright (c) 2011-2012 by Geekscape Pty. Ltd.
-- Documentation: http://http://geekscape.github.com/mqtt_lua
-- License: AGPLv3 http://geekscape.org/static/aiko_license.html
-- Version: 0.2 2012-06-01
--
--
--
-- File for publish
--
--
-- Description
-- ~~~~~~~~~~~
-- Publish an MQTT message on the specified topic with an optional last will.
-- ------------------------------------------------------------------------- --

local args =  {
  ['host'] = 'localhost',
  ['id'] = 'mqtt_pub_notebook',
  ['message'] = 'teste123',
  ['port'] = 1883,
  ['topic'] = '/teste',
  ['will_message'] = '.',
  ['will_qos'] = 0,
  ['will_retain'] = 0,
  ['will_topic'] = '.'
}
--[[ 
  Publish a message to a specified MQTT topic
  -d,--debug                                Verbose console logging
  -H,--host          (default localhost)    MQTT server hostname
  -i,--id            (default mqtt_pub)     MQTT client identifier
  -m,--message       (string)               Message to be published
  -p,--port          (default 1883)         MQTT server port number
  -t,--topic         (string)               Topic on which to publish
  -w,--will_message  (default .)            Last will and testament message
  -w,--will_qos      (default 0)            Last will and testament QOS
  -w,--will_retain   (default 0)            Last will and testament retention
  -w,--will_topic    (default .)            Last will and testament topic
]]

local MQTT = require("mqtt_library")
local json_lua = require("json_lua")

args.message = json_lua.encode({ 1, 2, 3, { x = 10 } })

if (args.debug) then MQTT.Utility.set_debug(true) end

local mqtt_client = MQTT.client.create(args.host, args.port)

if (args.will_message == "."  or  args.will_topic == ".") then
  mqtt_client:connect(args.id)
else
  mqtt_client:connect(
    args.id, args.will_topic, args.will_qos, args.will_retain, args.will_message
  )
end

mqtt_client:publish(args.topic, args.message)

mqtt_client:destroy()

-- ------------------------------------------------------------------------- --
