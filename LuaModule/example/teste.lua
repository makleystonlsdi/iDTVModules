
local msgDiscovery = '{"ID":"uuid","controllable":"actuator","environment":"bedroom","type":"colordimmable","states":{"color_state":{"unit":"discret_value","value":"red"},"intensity_state":{"unit":"continuou_value","value":"0.75"}},"functionalities":{"change_color":["set_RGB"],"regulator_light":["step_up","step_down","set"]}}'

local msgRead = '{"ID":"uuid","controllable":"actuator","environment":"bedroom","type":"colordimmable","states":{"color_state":{"unit":"discret_value","value":"blue"},"intensity_state":{"unit":"continuou_value","value":"0.75"}},"functionalities":{"change_color":["set_RGB"],"regulator_light":["step_up","step_down","set"]}}'


lua_module.topicsFilter('/discovery'..'/bedroom/actuator/colordimmable',msgDiscovery)

lua_module.topicsFilter('/read'..'/bedroom/actuator/colordimmable',msgRead)
