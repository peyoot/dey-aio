#! /bin/bash
#This scripts help you pack your release image files to DEY release folder
#check out https://github.com/peyoot/dey-aio for more informaiton
#Author: Robin Tu  
#twitter/X.com  peyoot_tu
#

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

_() { 
set -euo pipefail
# Declare an array so that we can capture the original arguments.
declare -a ORIGINAL_ARGS

prompt() {
  local VALUE
  # Hack: We read from FD 3 because when reading the script from a pipe, FD 0 is the script, not
  #   the terminal. We checked above that FD 1 (stdout) is in fact a terminal and then dup it to FD 3, thus we can input from FD 3 here.
  # We use "bold", rather than any particular color, to maximize readability. See #2037.
  echo -en '\e[1m' >&3
  echo -n "$1 [$2]" >&3
  echo -en '\e[0m ' >&3
  read -u 3 VALUE
  if [ -z "$VALUE" ]; then
    VALUE=$2
  fi
  echo "$VALUE"
}
prompt-numeric() {
  local NUMERIC_REGEX="^[0-9]+$"
  while true; do
    local VALUE=$(prompt "$@")
    if ! [[ "$VALUE" =~ $NUMERIC_REGEX ]] ; then
      echo "You entered '$VALUE'. Please enter a number." >&3
    else
      echo "$VALUE"
      return
    fi
  done
}
prompt-yesno() {
  while true; do
    local VALUE=$(prompt "$@")
    case $VALUE in
      y | Y | yes | YES | Yes )
        return 0
        ;;
      n | N | no | NO | No )
        return 1
        ;;
    esac
    echo "*** Please answer \"yes\" or \"no\"."
  done
}

platform-selector(){
  if [ "1" =  "$PLATFORM_SELECTOR" ]; then
    echo "You have choose cc6ul platform to publish"
#    SOURCE_PATH="cc6ulsbc/tmp/deploy/images/ccimx6ulsbc"
#        CPU="imx6ul"
#        SBC="ccimx6ulsbc"
#        KFS="ubifs"
#        RFS="ubifs"
#        XSERVER="x11"
#        UBOOTPRE="u-boot"
#        UBOOTEXT="imx"
  fi
  if [ "2" = "$PLATFORM_SELECTOR" ]; then
    SOURCE_PATH="tmp/deploy/images/ccimx8mn-dvk"
    CPU="imx8mn"
    SBC="ccimx8mn-dvk"
    KFS="vfat"
    RFS="ext4"
    XSERVER="xwayland"
    UBOOTPRE="imx-boot"
    UBOOTEXT="bin"
  fi
  if [ "3" = "$PLATFORM_SELECTOR" ]; then
        SOURCE_PATH="tmp/deploy/images/ccimx8x-sbc-pro"
        CPU="imx8x"
        SBC="ccimx8x-sbc-pro"
        KFS="vfat"
        RFS="ext4"
        XSERVER="xwayland"
        UBOOTPRE="imx-boot"
        UBOOTEXT="bin"
  fi
}


# define global variables

#check if parent folder is ready
#if [ ! -d release/ccimx6ul ]; then
#    mkdir -p release/ccimx6ul
#fi
#if [ ! -d release/ccimx8mnano ]; then
#    mkdir -p release/ccimx8mnano
#fi
#if [ ! -d release/ccimx8x ]; then
#    mkdir -p release/ccimx8x
#fi

exec 3<&1

#main process

BRANCH=""
PROJECT=""
DEY_VERSION=$(pwd |awk -F '/' '{print $(NF-1)}')
NAND_SOM=(
ccimx6ulsbc
ccimx6ulstarter
ccmp13-dvk
ccmp15-dvk
)
echo "dey version is ${DEY_VERSION}"


#check if any git repository avaialbe in current dey folder 
#if you run several projects with same SOM, it's very important to manage them with diferent branches 

if [ ! -d .git ]; then
  PROJECT_GIT="no"
  echo "You do not have any branch now! A git repository will facilitate you on revision management"

else
  PROJECT_GIT="yes"
  HEADP=$(cat .git/HEAD)
  BRANCH=${HEADP##*/}
#  BRANCH=$(git status |head -1 | awk '{ print $3 }')
#  BRANCH_TRUNC equal later part of the BRANCH, first part before - removed 
  BRANCH_TRUNC=${BRANCH#*-}
  echo "BRANCH is ${BRANCH}"
fi


# Automatically check projects in workspace 
echo "Try to find out your projects in workspace"
PLIST=( $(ls -l |grep -E '^d' |awk '{print $9}' |grep -v 'project_shared') )
NUM=${#PLIST[@]}
echo "Please select the hardware platform you are about to publish:"
for ((i=0;i<$NUM;i++)); do
  j=$((i+1))
  echo "${j} ${PLIST[${i}]}"
done
PROJECT_SELECTOR=$(prompt-numeric "Which one you are going to publish" "1")
if [ ${PROJECT_SELECTOR} -le ${NUM} ]; then
  PROJECT=${PLIST[((PROJECT_SELECTOR-1))]}
  echo "projects in array selected is ${PROJECT}"
#  PLATFORM=$(ls -d ./workspace/${PROJECT}/tmp/deploy/image/*/ 2>/dev/null | head -n 1)
  PLATFORM=$(grep 'MACHINE =' ./workspace/${PROJECT}/conf/local.conf | awk '{print $3}' | sed 's/"//g' )

#prepare display server type and FS type as part of path. by default DISPLAY_SERVER is xwayland in define in final else
  if [[ "${NAND_SOM[@]}"  =~ "${PLATFORM}" ]]; then
    echo "som flash type is nand"
    FS1="ubifs"
    FS2="ubifs"
  else
    echo "som flash type is emmc"
    FS1="vfat"
    FS2="ext4.gz"
  fi

  if [[ "${PLATFORM}" =~ "ccmp" ]] ; then
    echo "MPU type is ST"
    echo "need to copy  tf-a-${PLATFORM}-nand.stm32 and fip-${PLATFORM}-optee.bin later"
  else
    echo "MPU type is NXP"
    
  fi

#pick out special som or som group  that need to define linux kernel and uboot version seperately

  if [[ "${PLATFORM}" =~ "6ul" ]] ; then
    echo "it's 6ul platrom"
    DISPLAY_SERVER="x11"
    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0.0
        UBOOT_FILE="u-boot-${PLATFORM}-2020.04-r0.imx"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0.0\
        UBOOT_FILE="u-boot-${PLATFORM}-2020.04-r0.imx"
        ;;
      *)
        echo "wrong path to perform this script"
    esac
  
    SRC_DTB="${PLATFORM}/tmp/work/${PLATFORM}-dey-linux-gnueabi/linux-dey/5.4-r0/build/arch/arm/boot/dts/"
    SRC_UBOOT="${PLATFORM}/tmp/work/${PLATFORM}-dey-linux-gnueabi/u-boot-dey/2020.04-r0/deploy-u-boot-dey/"
  elif [[ "${PLATFORM}" =~ "ccmp" ]] ; then
    echo "it's ST platform"
  elif [[ "${PLATFORM}" =~ "imx9" ]] ; then
    echo "it's cc9 "

  else
     echo "common config for connectcore som"
     DISPLAY_SERVER="xwayland"

    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0.0
        UBOOT_VERSION=2020.04-r0

        UBOOT_FILE="u-boot-${PLATFORM}-2020.04-r0.imx"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0.0\
        UBOOT_FILE="u-boot-${PLATFORM}-2020.04-r0.imx"
        ;;
      *)
        echo "wrong path to perform this script"
    esac


  fi

else
  echo "please input the number within options.Abort now!"
  exit 1
fi



#image type selection
echo "Please choose the  image type you're about to publish"
echo "1. core-image-base"
echo "2. dey-image-webkit"
echo "3. dey-image-qt"
echo "4. dey-image-crank"
IMAGE_SELECTOR=$(prompt-numeric "which kind of image you're going to publish" "1")
if [ "1" = "$IMAGE_SELECTOR" ]; then
  IMAGE="core-image-base"

elif [ "2" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-webkit-${DISPLAY_SERVER}"

elif [ "3" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-qt-${DISPLAY_SERVER}"
elif [ "4" = "$IMAGE_SELECTOR" ]; then

  IMAGE="dey-image-crank-${DISPLAY_SERVER}"
else
  echo "please input the right choice"
  exit 1
fi



# preprare copy path 

SRC_BASE="${PLATFORM}/tmp/deploy/images/${PLATFORM}"
if [ "no" = "$PROJECT_GIT" ]; then
  DEST_PATH=" ../../release/${DEY_VERSION}/${PLATFORM}"
else
  DEST_PATH=" ../../release/${DEY_VERSION}/${PLATFORM}/${BRANCH}"
fi
if [ ! -d $DEST_PATH ]; then
  mkdir -p $DEST_PATH
fi

# review information before publish

echo "You are about to copy the ${PLATFORM} ${DEY_VERSION} images to release folde. Image type:${IMAGE} workspace git branch:${BRANCH}"
if prompt-yesno "Scripts will copy major images to release folder, continue?" yes; then
# copy from images folder
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.boot.${FS1} ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.recovery.${FS1} ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.${FS2} ${DEST_PATH}/
  if prompt-yesno "copy uboot/dtb/scripts files from tmp/deploy/images?" yes; then
    cp ${SRC_BASE}/${UBOOT_FILE} ${DEST_PATH}/
    cp ${SRC_BASE}/install_linux* ${DEST_PATH}/
    cp ${SRC_BASE}/boot.scr ${DEST_PATH}/
  else
    cp ${SRC_UBOOT}/${UBOOT_FILE} ${DEST_PATH}/
    cp ${SRC_UBOOT}/install_linux* ${DEST_PATH}/
    cp ${SRC_UBOOT}/boot.scr ${DEST_PATH}/
  fi
# copy developping dtb
  if [ "" != "${PROJECT}" ]; then
    cp ${SRC_DTB}/imx6ul-${PLATFORM}-${PROJECT}*.dtb* ${DEST_PATH}/
  fi

  echo "major images have been copied to release path"

  if prompt-yesno "Do you want to pack images to create an installer zip file?" yes; then
    sync
    sleep 2
    zip -j ${DEST_PATH}/my_sd_installer.zip ${DEST_PATH}/* -x ${DEST_PATH}/my_sd_installer.zip
  fi
else
  echo "you've chosen not to copy images to release folder! Make sure release folder already have the latest one. "
  echo "publishing to web/tftp will base on the images and zip files that are in release folder"
fi

if prompt-yesno "Would you like to publish the releases to the web/tftp server?" "no"; then
    echo "Please choose where you'd like publish:"
    echo "1. Publish to TFTP folder"
    echo "2. Publish to dey-mirror"
    echo "3. Publish to your own server"
    PUBLISH=$(prompt-numeric "Please choose where you'd like to publish releases" "1")
    if [ "1" = "$PUBLISH" ]; then
       TFTP_PATH=$(prompt "Please input the path of tftp folder:" "${DEST_PATH}/tftpboot")
       mkdir -p ${TFTP_PATH}
       echo "copying the release to the giving tftp folder"
       cp ${DEST_PATH}/${IMAGE}* ${TFTP_PATH}/
       cp ${DEST_PATH}/u-boot* ${TFTP_PATH}/
    elif [ "2" = "$PUBLISH" ]; then
       echo "copying the release to dey-mirror"
       USERNAME=$(prompt "Please input the username of dey-mirror server" "")
       SERVER_IP=
       if [ "robin" = "${USERNAME}" ]; then
         echo "you'll need to input correct password to authenticate yourself"
         rsync -avzP ${DEST_PATH}/*.zip '-e ssh -p 10022' robin@101.231.59.68:/home/robin/docker/dnmp/www/dey-mirror/dey-images/release
       else
         echo "You don't have the right to access eccee server"
         exit 1
       fi
    elif [ "3" = "$PUBLISH" ]; then
       echo "copying the release installer to your own server by scp command"
       SERVER_IP=$(prompt "Please input the server IP address" "")
       USERNAME=$(prompt "Please input the username of the erver" "")
       SERVER_PATH=$(prompt "Please input path on the server where you want to store the published installer" "")
       scp ${DEST_PATH}/my_sd_installer.zip ${USERNAME}@${SERVER_IP}:${SERVER_PATH}
    else
       echo "Please input the right choice"
       exit 1
    fi
fi


}
_ "$0" "$@"