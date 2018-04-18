# CASMOC
This module allows TV applications, aimed at digital TV middleware that make 
use of the Lua language (eg Ginga-NCL middleware), to be aware of the context 
of the physical environment in which the TV is located. 
Context data are obtained through the smart objects present in the physical 
environment, where the dynamic discovery of the services of these smart objects 
and the collection of these data are performed by the [SDPEU](https://github.com/makleystonlsdi/SDPEU).

This module maintains tables that store context data from the physical environment, 
as well as transparently manages the entire process of adding, removing and updating 
that data. Also, this module reflects the IoTTV-Ont conceptual model and offers an 
application programming interface (API) to aid the development of TV applications. 
The following shows how to use this module.

## How to use
To use this module, simply import the module to the TV application. 

#### Import
When unpacking this module next to your project you must perform ```import```. Follow model:
```lua
local CASMOC = require("CASMOC")
```

#### Configuration
After importing the CASMOC, you must configure the communication parameters with the SDPEU. 
This way, we must configure your address and port, for example. 
Other configurations already have default values, such as the QoS level to be 
used in the micro-broker (0), including the port itself (1883). 
The configuration basically is:

```lua
local settings = {}
settings.host_master = "192.168.0.10"
CASMOC.setMqttSettings(settings)
``` 

#### Defining the smart objects supported by the application
It is necessary for the developer to define which smart objects the 
application is interested in receiving data. Thus, it should be 
informed which home environment (eg room and room) the smart object 
must be to be used in the application, as well as what type 
(dimmerlamp and presencesensor). These semantic values, such as type 
and environment, must be followed using the terms specified in IoTTV-Ont.  
Here is an example:
```lua
local presencesensor = {}
presencesensor.Environment = 'Bedroom'
presencesensor.Type = "PresenceSensor"
```

In this way, when a smart object is found in the physical environment 
containing these characteristics, it will be stored in an internal table 
to the module and will keep its values always updated. Also, when the 
smart object status changes and you send a notification to the TV 
application, it may take some action. 
Here's how to implement the notifications and status read actions:

```lua
local presencesensor = {}
presencesensor.Environment = 'bedroom'
presencesensor.Type = "presencesensor"
function presencesensor:receiveNotification(notificationfunctionality)
	print("Notifications received")
end
```
```ReceiveNotification``` allows written encoding on your body to run whenever 
there is a smart object notification. 
To find out which notification was generated, 
simply see its name: ```notificationname```. 

To inform the SDPEU of which smart objects have been specified and which must 
be heard by running the ```receiveNotifications```, you must pass these objects 
as parameters in a table in the ```setSmartObjectListener``` method. Follow model:

```lua
CASMOC.setSmartObjectsListener({presencesensor})
```

#### Defining the receipt of multimodal interactions

The following example presents an implementation to receive multimodal 
data made by viewers with the TV application. This implementation receives 
as parameter an Event table and the portable device that generated such interaction.
```lua
local events = {}
function events:receiveEvents(Portable, Events)
	for i = 1, #Events do
		print("The user "..Portable.Person.givenName.." interacted by performing the "..Events[i].." action through the "..Portable.Type.." portable device")
	end
end
```

We must inform CASMOC of the listener for the events. Follow model:

```lua
CASMOC.setEventsListener(events)
```

#### Changing aspects of the physical environment

To receive the context data of the physical environment, simply make the following call:

```lua
local dataContext = CASMOC.getContextDataTable()
```

The return of this call is a table containing two keys: smartobjects and portabledevices. So, to use it separately, one can do:

```lua
local contextData = m_hub_tv_lua.getContextDataTable()
local smartObjects = contextData.smartobjects
local portableDevices = contextData.portabledevices
```

To make some consultation about the viewers present in the physical environment, just do:
```lua
if(#portableDevices > 0)then
	for i = 1, #portableDevices do
		print(portableDevices[i].Person.name)
	end
end
```

See the examples in this repository.

## More
[IoTTV Project](http://www.lsdi.ufma.br/~iottv)

[Laboratório de Sistemas Distribuídos Inteligentes (LSDi)](http://www.lsdi.ufma.br)

[Universidade Federal do Maranhão (UFMA)](http://www.ufma.br)
