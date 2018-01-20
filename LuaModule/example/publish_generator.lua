package.path = package.path .. ";../?.lua"
package.path = package.path .. ";../libs/?.lua"

local lua_module = require 'lua_module'
local log = false

local mqtt_settings = {}
mqtt_settings.host_mhubtv = 'localhost'
mqtt_settings.id = 'generator'
mqtt_settings.debug = false
lua_module.setMqttSettings(mqtt_settings)

local colors = {'blue','green','red','brown','black','purple'}
local idsos = {'idA','idB','idC','idD','idE','idF','idG','idH','idI','idJ','idK'}
local types = {'colordimmableA','colordimmableB','colordimmableC','colordimmableD','colordimmableE'}
local environments = {'bedroom', 'roomdiming', 'room', 'kitchen'}
--local idsodiscovered = {}
local smartObjectsPresent = {}

local interactions = {'left','right','up','down'}

local devices = {
    {['id'] = 'pA',
        ['environment']   = 'bedroom',
        ['type']   = 'smartphone',
        ['person']   = {
            ['name'] = 'Danne'}},
    {['id'] = 'pB',
        ['environment']   = 'bedroom',
        ['type']   = 'smartphone',
        ['person']   = {
            ['name'] = 'Lelê'}},
    {['id'] = 'pC',
        ['environment']   = 'bedroom',
        ['type']   = 'tablet',
        ['person']   = {
            ['name'] = 'Sussu'}}
}

local devicesPresents = {}

local clock = os.clock
local time_is_alive = 6 --seconds
local last_check_alive = clock()

function sleep(n)  -- seconds
    local t0 = clock()
    while clock() - t0 <= n do end
end

function diffClock(initTime, time)
    if((clock() - initTime) > time)then
        return true
    end
end

function getSizeSmartObjectTable()
    local i=0
    for k,v in pairs(smartObjectsPresent)do
        i = i+1
    end
    return i
end

function publishDicoverySmartObject()
    if(#idsos == #smartObjectsPresent)then
        return
    end

    local n = math.random(#idsos)
    for k, v in pairs(smartObjectsPresent)do
        if(idsos[n] == v.id)then
            return  publishDicoverySmartObject()
        end
    end

    local obj = {}
    obj.id = idsos[n]
    obj.type = types[math.random(#types)]
    obj.environment = environments[math.random(#environments)]
    obj.controllable = "actuator"

    obj.states = {}
    obj.states.color_state = {}
    obj.states.color_state.unit = "discret_value"
    obj.states.color_state.value = colors[math.random(#colors)]

    obj.states.intensity_state = {}
    obj.states.intensity_state.unit = "continuou_value"
    obj.states.intensity_state.value = "0.75"

    obj.functionality = {}
    obj.functionality.notificationfunctionality = {}
    obj.functionality.notificationfunctionality.notificationname = ''

    obj.functionality.controllfunctionality = {}
    obj.functionality.controllfunctionality.change_color = {"set_RGB"}
    obj.functionality.controllfunctionality.regulator_light = {"step_up","step_down","set"}

    table.insert(smartObjectsPresent, obj)

    lua_module.postMessage('/smart_object_discovery/'..obj.environment..'/'..obj.controllable..'/'..obj.type, obj)
    if(log)then
        print("discovery so: id = "..obj.id..", type = "..obj.type)
    end
end

function publishDisconnectSmartObject()
    if(getSizeSmartObjectTable()==0)then
        publishDicoverySmartObject()
    else
        local index = math.random(getSizeSmartObjectTable())
        if(smartObjectsPresent[index])then
            local obj = smartObjectsPresent[index]
            lua_module.postMessage('/smart_object_disconnected', obj.id)
            if(log)then
                print("disconnect so: id = "..obj.id)
            end
            --smartObjectsPresent[index] = nil
            table.remove(smartObjectsPresent, index)
        else
            return publishDicoverySmartObject()
        end
    end
end

function publishReadSmartObject()
    if(getSizeSmartObjectTable()==0)then
        publishDicoverySmartObject()
    else
        local index = math.random(getSizeSmartObjectTable())
        if(smartObjectsPresent[index]) then
            smartObjectsPresent[index].environment = environments[math.random(#environments)]
            smartObjectsPresent[index].states.color_state.value = colors[math.random(#colors)]

            lua_module.postMessage('/smart_object_read/'..smartObjectsPresent[index].environment..'/'..smartObjectsPresent[index].controllable..'/'..smartObjectsPresent[index].type, smartObjectsPresent[index])
            if(log)then
                print("read so: id = "..smartObjectsPresent[index].id..", Env = "..smartObjectsPresent[index].environment..", color = "..smartObjectsPresent[index].states.color_state.value)
            end
        else
            return publishReadSmartObject()
        end
    end
end

function publishReadPortableDevice()
    local n = math.random(10)
    local index = nil
    local flag = true
    if(n>0)then
        if(#devices ~= #devicesPresents)then
            index = math.random(#devices)
            for k,v in pairs(devicesPresents) do
                if(devices[index].id ~= v.id)then
                    flag = false
                end
            end
            if(flag)then
                table.insert(devicesPresents, devices[index])
            end
        end
    end
    if(#devicesPresents == 0)then
        table.insert(devicesPresents, devices[math.random(#devices)])
    end
    for k, v in pairs(devicesPresents)do
        v.interactions = {interactions[math.random(#interactions)]}

        local vJ = v
        lua_module.postMessage('/portable_device/'..v.environment..'/'..v.type, vJ)
        if(log)then
            print("read pd: id = "..v.id..", person = "..v.person.name..", interaction = "..v.interactions[1])
        end
    end
end

function publishIsAlivePortableDevice()
    if(#devicesPresents == 0)then
        table.insert(devicesPresents, devices[math.random(#devices)])
    end
    for k, v in pairs(devicesPresents)do
        lua_module.postMessage('/alive_portable_device', v.id)
        if(log)then
            print("is alive g: id = "..v.id)
        end
    end
    local n = math.random(10)
    if(n>7)then
        table.remove(devicesPresents, math.random(#devicesPresents))
    end
end

local functions = {}
functions[#functions + 1] = publishDicoverySmartObject
functions[#functions + 1] = publishDicoverySmartObject
functions[#functions + 1] = publishDisconnectSmartObject
functions[#functions + 1] = publishReadPortableDevice
functions[#functions + 1] = publishReadPortableDevice
functions[#functions + 1] = publishReadSmartObject
functions[#functions + 1] = publishReadSmartObject
functions[#functions + 1] = publishReadSmartObject
functions[#functions + 1] = publishReadSmartObject
functions[#functions + 1] = publishReadSmartObject
functions[#functions + 1] = publishReadSmartObject

local sizeFunctionsDefault = #functions

function randon()
    while true do
        local n = math.random(#functions)
        local f = functions[n]
        f()
        sleep(1)
        local i = #smartObjectsPresent
        if(i == #idsos-1)then
            functions[sizeFunctionsDefault + 1] = publishDisconnectSmartObject
            functions[sizeFunctionsDefault + 2] = publishDisconnectSmartObject
        elseif (i == 2) then
            functions[sizeFunctionsDefault + 1] = nil
            functions[sizeFunctionsDefault + 2] = nil
        end
        if(diffClock(last_check_alive, time_is_alive))then
            last_check_alive = clock()
            publishIsAlivePortableDevice()
            print("***** Total de SO: ".. i .." *****")
        end
    end
end

randon()















