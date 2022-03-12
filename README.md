#### Description
DEY-AIO stands for Digi Embedded Yocto All In One.
It contain docker-compose file and also some scripts to help you pack and publish your DEY images.

**[[中文说明]](README.md)**

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

├── dey30                      DEY version
│   ├── workspace
├── dey32
│   ├── workspace
├── dey33
│   ├── workspace
├── release                    released folders (when you use publishing tools)
│   ├── dey30                   
│        ├── cc6ul
│        ├── ccmp15
│        ├── cc8mn
│        ├── cc8mm
│        ├── cc8x
│        ├── ...
│   ├── dey32                   
│        ├── ...
│   └── dey33                   
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
3. Add current user to group `docker`：
    ```
    $ sudo gpasswd -a ${USER} docker
    ```
4. Start docker containers
  * Initialization 
   Please note, If it's the first time you use the specific version , initialization will be needed to generate workspace folder within it. Go to the dey version folder and then run:
```
docker-compose up
```
Wait till everything is ready and use ctrl+c to exit. Now workspace folder have been generated. You need to give this folder full read/write priviledge so that containers can work as expected.
```
chmod 777 workspace
```
Now initialization finished and and then every time you want to run dey, just use :
```
docker-compose run dey<version>
```
for example, go to the initialized dey30 folder and run
```
docker-compose run dey30
```

  * General Usage
To start the specific dey container, got to folder and run:
```
docker-composerun dey<version>
```
Here, dey<version> can be dey30,dey32,etc.

To exit, Please type `exit` inside the container and then run: `docker-compose down` to remove this container.



## 4. License
MIT
