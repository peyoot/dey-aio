#### Description
DEY-AIO stands for Digi Embedded Yocto All In One.
It contain docker-compose file and also some scripts to help you pack and publish your DEY images.

Now dey-aio also support DEY native way as well as docker way to develop projects in the same place. There's a meta-custom layer by default installed and can be used as a reference to pack your own rootfs with your app and config files.

**[[中文说明]](README-cn.md)**

## 1. Feature
1. Completely open source.
2. Support Multiple DEY versions (3.0 and upwards)
3. Built-in packing and publishing tools.
4. Support manage your own workspace git repositories under subfolders.
5. more...
## 2.  Software Architecture
dey-aio
```
/
├── dey4.0                      DEY version
│   ├──docker-compose.yml
│   ├── publish.sh
│   ├── workspace
├── dey3.2                   (only available in legacy v1.1)
│   ├──docker-compose.yml
│   ├── publish.sh
│   ├── workspace
| ...
├── release                    released folders (when you use publishing tools)
│   ├── dey4.0                   
│        ├── cc6ul
│        ├── ccmp15
│        ├── cc8mn
│        ├── cc8mm
│        ├── cc8x
│        ├── cc93
│        ├── ...
│   ├── dey3.2                   
│        ├── ...
│   └ ...
|
├── meta-custom
├── tools                       mkproject.sh and publishing tools
│   ├── publish.sh
|   |__ mkproject.sh
├── README.md
└── README-cn.md
```
## 3. Usage
Latest version use repo tool to manage the source code tree. Please also refer to https://github.com/peyoot/dey-aio-manifest

For run dey in docker way, you can also use the following instrunctions.

1. Install `git`, `docker` and `docker-compose`;
2. Clone project:
    ```
    $ git clone https://github.com/peyoot/dey-aio.git
    ```
3. Add current user to group `docker` and reboot：
    ```
    $ sudo gpasswd -a ${USER} docker
    $ sudo reboot
    ```
4. Start docker containers
  * Initialization 
   Please note if it's the first time you use the specific version , initialization will be needed to generate workspace folder within it. Go to the dey version folder and then run:
```
docker-compose up
```
Wait till everything is ready and it will exit automatically. Now workspace folder have been generated. You need to give this folder full read/write priviledge so that containers can work as expected.
```
sudo chmod 777 workspace
```
Now initialization finished and and then every time you want to run dey, just use :
```
docker-compose run dey<version>
```
for example, go to the initialized dey3.2 folder and run
```
docker-compose run dey3.2
```

  * General Usage
To start the specific dey container, got to folder and run:
```
docker-compose run dey<version>
```
Here, dey<version> can be dey3.0,dey3.2,etc.

To exit, Please type `exit` inside the container. In this way, the container still runing and you can go back to the container by "docker exec -it  <container id> bash " to go back to dey container.
To find out the runing/stopped container ID, use "docker ps" or "docker ps -a"

if you want to remove container, just un : `docker-compose down` to remove it. 

  * additional packages 
Scripts will need to use zip to pack the installer. so please install it in container

sudo apt install zip


Now repository use peyoot/dey instead of official digidotcom/dey, no additional package need to be updated or installed.

But if you use digidotcom/dey:dey3.0-r4, You'll need to upgrade and install additional packages as below
```
sudo apt update -y
sudo apt upgrade -y
sudo apt install git-lfs -y
```
dey is also the default password you need to input


## 4. License
MIT
