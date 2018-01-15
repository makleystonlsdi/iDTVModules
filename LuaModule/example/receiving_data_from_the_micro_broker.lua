-- Imports
package.path = package.path .. ";../?.lua"
local lua_module = require("lua_module")

local mqtt_settings = {}
mqtt_settings.host_mhubtv = 'localhost'
mqtt_settings.debug = false
lua_module.setMqttSettings(mqtt_settings)

-- Environment
local environmentsTable = {'+'}
lua_module.setEnvironmentTable(environmentsTable)

-- Topics subscribe
lua_module.addTopic('/actuator/dimmerlamp')
lua_module.addTopic('/actuator/presencesensor')
lua_module.addTopic('/actuator/colordimmableA')
lua_module.addTopic('/actuator/colordimmableB')

-- Defining user interactions
local interactionsOfApplication = {
  {['left']   = {['description'] = 'Move to the left',  ['action'] = function() print('leftEvent')  end}},
  {['right']  = {['description'] = 'Move to the right', ['action'] = function() print('rightEvent') end}},
  {['up']     = {['description'] = 'Move to the up',    ['action'] = function() print('upEvent')    end}},
  {['down']   = {['description'] = 'Move to the down',  ['action'] = function() print('downEvent')  end}}
  }
lua_module.setInteractionsTable(interactionsOfApplication)

-- Enable interaction of user
lua_module.enableInteractions(true)

lua_module.topicsFilter('/test', '123')

-- Subscribe all topics
lua_module.subscribeAllTopics()

--local table = lua_module.getSmartObjectsTable()
--print(#table)
--print(table[1].states.color_state.value)


