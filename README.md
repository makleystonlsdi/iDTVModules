# ![IoTTV](http://lsdi.ufma.br/~dannepereira/images/iottv-mini.png)

# Comunication Abstraction and Smart Object Monitor Component - CASMOC
The Internet of Things (IoT) is present in many domains, such as industries, 
cities and smart houses. The latter can make use of the TV to manage the things of IoT, 
allowing a greater degree of immersion to the viewers of a presented content.
 For example, a video can be televised where, during the course of its narrative, 
 the aspects of the physical presentation environment were adapted to the presented 
 content: regulating the intensity of illumination, the temperature of the environment, 
 the activation of flavorings, among others.

In this context, the project [IoTTV](http://www.lsdi.ufma.br/~iottv) seeks to 
converge both areas with the objective of:
* Allow the application running on the TV to change aspects of the physical environment;
* Allow content displayed on TV to be aware of context data of the physical presentation environment;
* Allow the viewer to interact in various ways with the application running on the TV.

To this end, a software infrastructure has been developed that makes use of 
mobile devices (and smartphones and tablets) to mediate the
 communication between the TV application and the things of IoT. More about the
  project and infrastructure of software can be found [here](http://www.lsdi.ufma.br/~iottv).
  
Basically, this project contains software that will run on both TV and mobile devices. 
Since then, the [SDPEU](https://github.com/makleystonlsdi/SDPEU) application 
(Available in the Git-Hub) is responsible for exchanging data with IoT stuff. 
On the other hand, these TV modules, which must be imported by the applications, 
are responsible for receiving the SDPEU data and locally storing the information 
of each thing, allowing the applications to make use of this context data.

On this page you will find modules from various digital 
TV middleware. Each contains explanations and examples of its use.

Currently Available Modules:
* [CASMOC (Lua)](https://github.com/makleystonlsdi/iDTVModules/tree/master/CASMOC)

# More
[IoTTV Project](http://www.lsdi.ufma.br/~iottv)

[Laboratório de Sistemas Distribuídos Inteligentes (LSDi)](http://www.lsdi.ufma.br)

[Universidade Federal do Maranhão (UFMA)](http://www.ufma.br)
