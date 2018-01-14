-- Imports
io.stdout:setvbuf'no'
package.path = package.path .. ";../libs/luapower/?.lua"
package.path = package.path .. ";../?.lua"

local ffi = require'ffi'
local thread = require'thread'
local pthread = require'pthread'
local luastate = require'luastate'
local time = require'time'
local glue = require'glue'

local lua_module = require("lua_module")

-- Topics subscribe
lua_module.addTopic('/bedroom/actuator/dimmerlamp')
lua_module.addTopic('/bedroom/actuator/presencesensor')
lua_module.addTopic('/bedroom/actuator/colordimmable')

local mqtt_settings = {}
mqtt_settings.host_mhubtv = 'localhost'
lua_module.setMqttSettings(mqtt_settings)

--lua_module.subscribeAllTopics()
thread.new(lua_module.subscribeAllTopics()):join()
print("Criei a thread")  
