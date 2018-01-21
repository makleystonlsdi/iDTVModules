# ![IoTTV](http://lsdi.ufma.br/~dannepereira/images/iottv-mini.png)

# iDTVModules
A Internet das Coisas (IoT) está presente em diversos domínios, como indústrias, cidades e casas inteligentes. 
Este último pode fazer uso da TV para gerenciar as coisas da IoT, permitindo um maior grau de imersão aos telespectadores de um conteúdo apresentado. 
Exemplificando, pode-se televisionar um vídeo onde ao decorrer de sua narrativa os aspectos do ambiente físico de apresentação fossem se adequando ao conteúdo apresentado: 
regulando a intensidade de iluminação, a temperatura do ambiente, o acionamento de aromatizantes, dentre outros.

Nesse contexto, o projeto [IoTTV](http://www.lsdi.ufma.br/~iottv) busca convergir ambas áreas com objetivo de:
* Permitir que a aplicação em execução na TV possa alterar aspectos do ambiente físico; 
* Permitir que o conteúdo apresentado na TV possa estar ciênte de dados de contexto do ambiente físico de apresentação;
* Permitir que o telespectador possa interagir por diversos modos com a aplicação em execução na TV.

Para tanto, foi desenvolvida uma infraestrutura de *software* que faz uso de dispositivos móveis (*e. g. smartphones* e *tablets*) para intermediar a comunicação entre a aplicação de TV e as coisas da IoT. 
Mais sobre o projeto e a infraestrutura de *software* pode ser encontrado [aqui](http://www.lsdi.ufma.br/~iottv).

Basicamente, este projeto contém *softwares* que serão executados tanto na TV quanto nos dispositivos móveis. 
Desde modo, o aplicativo [M-Hub-TV](https://github.com/makleystonlsdi/MHubTV) (Disponível no Git-Hub) é responsável por trocar dados com as coisas da IoT. 
Por outro lado, estes módulos de TVs, que devem ser importados pelas aplicações, são responsáveis por receber os dados do [M-Hub-TV](https://github.com/makleystonlsdi/MHubTV) e armazenar localmente as informações de cada coisa, permitindo que as aplicações possam fazer uso desses dados de contexto.

Nesta página você encontrará módulos de diversos *middlewares* de TVs digitais. 
Cada um contém explicações e exemplos de sua utilização.

Módulos disponíveis atualemente:
* [M-Hub-TV-Lua](https://github.com/makleystonlsdi/iDTVModules/tree/master/LuaModule)

# Saiba mais
[Projeto IoTTV](http://www.lsdi.ufma.br/~iottv)

[Laboratório de Sistemas Distribuídos Inteligentes (LSDi)](http://www.lsdi.ufma.br)

[Universidade Federal do Maranhão (UFMA)](http://www.ufma.br)
