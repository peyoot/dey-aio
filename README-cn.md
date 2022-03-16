#### 简介
dey-aio是Digi Embedded Yocto All In One的缩写。本项目旨在帮助用户使用docker-compose的方式快速搭建不同版本的dey，并使用发布工具，将需要的镜像或卡刷文件打包到发布目录或是dey-mirror镜像服务器，以便通过tftp服务器刷固件或是快速和其它人分享相关文件。

**[[英文说明]](README.md)**

## 1. 特性
1. 完全开源，可直接使用，或是自由修改用于发布到自己的内部服务器上
2. 支持不同的DEY版本 (3.0 及其以上，持续更新中)
3. 内置打包和发布工具，以方便测试编译结果.
4. 支持目录内自己用git管理自己的workspace版本变动
5. 针对中国区编译环境优化
等等...
## 2.  目录结构
dey-aio
```
/
├── dey30                      DEY版本
│   ├── workspace
├── dey32
│   ├── workspace
├── dey33
│   ├── workspace
├── release                    发布文件夹 (使用tools下的工具时可选发布到这里或服务器上)
│   ├── dey30                  不同版本下的不同硬件平台的发布文件
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
├── tools                       打包和发布工具
│   ├── publish.sh              
├── docker-compose.sample.yml   docker-compose sample
└── env.smaple                  environment file sample
```
## 3. 用法
1. 安装 `git`, `docker` 和 `docker-compose`;
比如ubuntu下：
```shell
sudo apt update
sudo apt install docker.io docker-compose
```
2. 克隆本项目:
    ```
    $ git clone https://github.com/peyoot/dey-aio.git
    ```
3. 添加当前用户到docker用户组并重启：
    ```
    $ sudo gpasswd -a ${USER} docker
    $ sudo reboot
    ```
4. 开始使用容器化的dey-aio中的各种dey版本
  重启后，当前用户就可以直接使用docker和docker-compose的各种命令了。
  * 初始化
  
  第一次使用某个版本的dey，需要先初始化一下，以便生成workspace目录并赋予完整权限，对应版本的dey容器才能正常使用。
  进入相关的dey目录，比如dey30，然后运行
  ```
docker-compose up
```
等到相关镜像下载并生成好后，会自动退出。此时该目录下已经生成了worksapce目录，需要赋予777完整读写权限。

```
sudo chmod 777 workspace
```
初始化到此就结束了，以后就可以直接运行该版本的容器。
要运行该DEY版本主，用：

```
docker-compose run dey<版本号>
```
比如运行dey3.0容器：

```
docker-compose run dey30
```
  * 日常使用
要运行某个版本的dey，请到相应的目录下：

```
docker-composerun dey<版本号>
```
dey<版本号>可以是dey30,dey32等已经初始化好的容器

要退出容器，在容器内的命令行输入：exit ，并用docker-compose down来移除相关容器

   * 容器内必须的安装包
对于DEY3.0，由于镜像构建时间较早，为了能正常使用，需要在dey3.0容器内安装额外的软件包，以应对最新的dey recipe需求。
执行这些命令：
sudo apt update -y
sudo apt upgrade -y
sudo -y apt install git-lfs
在执行sudo需要输入密码，请输入dey



## 4. License
MIT
