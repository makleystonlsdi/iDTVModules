local json_lua = require("json_lua")
local lua_module = require("lua_module")

local msgDiscovery = '{"ID":"uuid","controllable":"actuator","environment":"bedroom","type":"colordimmable","states":{"color_state":{"unit":"discret_value","value":"red"},"intensity_state":{"unit":"continuou_value","value":"0.75"}},"functionalities":{"change_color":["set_RGB"],"regulator_light":["step_up","step_down","set"]}}'

local msgRead = '{"ID":"uuid","controllable":"actuator","environment":"bedroom","type":"colordimmable","states":{"color_state":{"unit":"discret_value","value":"blue"},"intensity_state":{"unit":"continuou_value","value":"0.75"}},"functionalities":{"change_color":["set_RGB"],"regulator_light":["step_up","step_down","set"]}}'

--local obj = json_lua.decode(msg)

lua_module.addTopic('/bedroom/actuator/colordimmable')
lua_module.addTopic('/bedroom/actuator/dimmerlamp')
lua_module.addTopic('/bedroom/actuator/presencesensor')

lua_module.removeTopic('/bedroom/actuator/dimmerlamp')

lua_module.addTopic('/bedroom/actuator/dimmerlamp2')
lua_module.addTopic('/bedroom/actuator/dimmerlamp3')
local topics = lua_module.getTopicsList()
for k, v in pairs(topics)do
    print(k..' - '..v)
end

lua_module.main('/discovery'..'/bedroom/actuator/colordimmable',msgDiscovery)

lua_module.main('/read'..'/bedroom/actuator/colordimmable',msgRead)

local table = lua_module.getSmartObjectsTable()
--print(table[1].states.color_state.value)


