#### Description
DEY-AIO stands for Digi Embedded Yocto All In One.
It contain docker-compose file and also some scripts to help you pack and publish your DEY images.

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
├── dey3.0                      DEY version
│   ├── workspace
├── dey3.2
│   ├── workspace
├── release                    released folders (when you use publishing tools)
│   ├── dey3.0                   
│        ├── cc6ul
│        ├── ccmp15
│        ├── cc8mn
│        ├── cc8mm
│        ├── cc8x
│        ├── ...
│   ├── dey3.2                   
│        ├── ...
│   └── dey3.3                   
│        ├── ...
├── tools                       publishing tools
│   ├── publish.sh
├── docker-compose.sample.yml   docker-compose sample
└── env.smaple                  environment file sample
```
## 3. Usage
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
for example, go to the initialized dey3.0 folder and run
```
docker-compose run dey3.0
```

  * General Usage
To start the specific dey container, got to folder and run:
```
docker-composerun dey<version>
```
Here, dey<version> can be dey3.0,dey3.2,etc.

To exit, Please type `exit` inside the container and then run: `docker-compose down` to remove this container.


## 4. License
MIT
