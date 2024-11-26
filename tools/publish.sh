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



exec 3<&1

#main process

BRANCH=""
PROJECT=""
DEY_VERSION=$(pwd |awk -F '/' '{print $(NF)}')
DISPLAY_SERVER="xwayland"
ISROS="no"

NAND_SOM=(
ccimx6ulsbc
ccimx6ulstarter
ccmp13-dvk
ccmp15-dvk
)

ARM64_SOM=(
ccimx8mm-dvk
ccimx8mn-dvk
ccimx8x-sbc-express
ccimx8x-sbc-pro
ccimx91-dvk
ccimx93-dvk
ccmp25-dvk
)

if prompt-yesno "check and install some prerequisite packages?" no; then
  if [ "$(id -u)" -eq 0 ]; then
    PACKAGE_UPDATE="apt -qq update"
    PACKAGE_INSTALL_BASE="apt -qq -y install "
  else
    PACKAGE_UPDATE="sudo apt -qq update"
    PACKAGE_INSTALL_BASE="sudo apt -qq -y install "
  fi
  eval ${PACKAGE_UPDATE}
  additional_packages=("curl" "sshpass" "zip" "rsync")
  for pack_str in ${additional_packages[@]}; do
    if [ ! -e /usr/bin/${pack_str} ]; then
      PACKAGE_INSTALL=${PACKAGE_INSTALL_BASE}${pack_str}
      eval ${PACKAGE_INSTALL}
    fi
  done
  echo "Now all prerequisite packages installed. "
else
  echo "Ignore to check prerequisite packages. Please remember to install missing packages first if any error happens"
fi


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
PLIST=( $(ls -l workspace|grep -E '^d' |awk '{print $9}' |grep -v 'project_shared') )
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
  PLATFORM_=$(echo ${PLATFORM} | tr '-' '_')
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

  if [[ "${ARM64_SOM[@]}"  =~ "${PLATFORM}" ]]; then
    echo "som arch type is arm64"
    SOM_ARCH="arm64"
  else
    echo "som arch type is arm"
    SOM_ARCH="arm"
  fi

#pick out special som or som group  that need to define linux kernel and uboot version seperately

  if [[ "${PLATFORM}" =~ "6ul" ]] ; then
    echo "it's 6ul platrom"
    DISPLAY_SERVER="x11"
    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.imx"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.imx"
        ;;
      *)
        echo "wrong path to perform this script"
    esac


  elif [[ "${PLATFORM}" =~ "imx8m" ]] ; then
    echo "it's cc8 platrom"
    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="imx-boot-${PLATFORM}.bin"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="imx-boot-${PLATFORM}.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac



  elif [[ "${PLATFORM}" =~ "imx8x" ]] ; then
    echo "it's cc8 platrom"
    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="imx-boot-${PLATFORM}*.bin"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="imx-boot-${PLATFORM}*.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac

  elif [[ "${PLATFORM}" =~ "mp2" ]] ; then
    echo "it's ST platform"
    DISPLAY_SERVER="wayland"

    echo "need to copy  tf-a-${PLATFORM}-*.stm32 and fip-${PLATFORM}-optee.bin later"
    case ${DEY_VERSION} in
      dey4.0)
        LINUX_KERNEL=6.1-r0
        UBOOT_VERSION=2022.10-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac

  elif [[ "${PLATFORM}" =~ "mp1" ]] ; then
    echo "it's ST platform"
    DISPLAY_SERVER="wayland"

    echo "need to copy  tf-a-${PLATFORM}-nand.stm32 and fip-${PLATFORM}-optee.bin later"
    case ${DEY_VERSION} in
      dey4.0)
        LINUX_KERNEL=5.15-r0
        UBOOT_VERSION=2021.10-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac

  elif [[ "${PLATFORM}" =~ "imx9" ]] ; then
    echo "it's cc9 "

    case ${DEY_VERSION} in
      dey4.0)
        LINUX_KERNEL=6.1-r0
        UBOOT_VERSION=2023.04-r0
        UBOOT_FILE="imx-boot-${PLATFORM}*.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac

  else
    echo "common config for connectcore som"

    case ${DEY_VERSION} in
      dey3.2)
        LINUX_KERNEL=5.4-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.bin"
        ;;
      dey4.0)
        LINUX_KERNEL=5.15-r0
        UBOOT_VERSION=2020.04-r0
        UBOOT_FILE="u-boot-${PLATFORM}-${UBOOT_VERSION}.bin"
        ;;
      *)
        echo "wrong path to perform this script"
    esac

  fi

else
  echo "please input the number within options.Abort now!"
  exit 1
fi

SRC_DTB="workspace/${PROJECT}/tmp/work/${PLATFORM_}-dey-linux/linux-dey/${LINUX_KERNEL}/build/arch/${SOM_ARCH}/boot/dts/digi"
SRC_UBOOT="workspace/${PROJECT}/tmp/work/${PLATFORM_}-dey-linux/u-boot-dey/${UBOOT_VERSION}/deploy-u-boot-dey"


#image type selection
echo "Please choose the  image type you're about to publish"
echo "1. core-image-base"
echo "2. dey-image-webkit"
echo "3. dey-image-qt"
echo "4. dey-image-crank"
echo "5. dey-image-lvgl"
echo "6. manually input an image name"
IMAGE_SELECTOR=$(prompt-numeric "which kind of image you're going to publish" "1")
if [ "1" = "$IMAGE_SELECTOR" ]; then
  IMAGE="core-image-base"
elif [ "2" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-webkit-${DISPLAY_SERVER}"
elif [ "3" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-qt-${DISPLAY_SERVER}"
elif [ "4" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-crank-${DISPLAY_SERVER}"
elif [ "5" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-lvgl-${DISPLAY_SERVER}"
elif [ "6" = "$IMAGE_SELECTOR" ]; then
  IMAGE=$(prompt "Please input an image name:" "core-image-mono")
else
  echo "please input the right choice"
  exit 1
fi


# preprare copy path 

SRC_BASE="workspace/${PROJECT}/tmp/deploy/images/${PLATFORM}"
SRC_SDK="workspace/${PROJECT}/tmp/deploy/sdk"

if [ "no" = "$PROJECT_GIT" ]; then
  DEST_PATH="./release/${PROJECT}"
else
  DEST_PATH="./release/${PROJECT}/${BRANCH}"
fi
if [ ! -d $DEST_PATH ]; then
  mkdir -p $DEST_PATH
fi

# review information before publish

echo "Here is the summary upon your choice. Platform: ${PLATFORM}; DEY version: ${DEY_VERSION}; Image type: ${IMAGE}; Workspace git branch:${BRANCH}"
if prompt-yesno "Scripts will copy major images to release folder, continue?" yes; then
# copy from images folder
  cp ${SRC_BASE}/${IMAGE}*-${PLATFORM}.boot.${FS1} ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}*-${PLATFORM}.recovery.${FS1} ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}*-${PLATFORM}.${FS2} ${DEST_PATH}/
  if prompt-yesno "copy uboot/dtb/scripts files from tmp/deploy/images?" yes; then
    cp ${SRC_BASE}/${UBOOT_FILE} ${DEST_PATH}/
    cp ${SRC_BASE}/install_linux* ${DEST_PATH}/
    cp ${SRC_BASE}/boot.scr ${DEST_PATH}/
    cp ${SRC_BASE}/*.dtb ${DEST_PATH}/

    if [[ "${PLATFORM}" =~ "mp" ]] ; then
      echo "copy ST platform bootloader"
      cp ${SRC_BASE}/tf-a-${PLATFORM}-*.stm32 ${SRC_BASE}/metadata-${PLATFORM}*.bin ${SRC_BASE}/fip-${PLATFORM}-*.bin ${DEST_PATH}/
    fi
  else
    if [ ! -d ${DEST_PATH}/dtb ]; then
      mkdir -p ${DEST_PATH}/dtb
    fi
    cp ${SRC_UBOOT}/${UBOOT_FILE} ${DEST_PATH}/
    cp ${SRC_UBOOT}/install_linux* ${DEST_PATH}/
    cp ${SRC_UBOOT}/boot.scr ${DEST_PATH}/
    cp ${SRC_DTB}/* ${DEST_PATH}/dtb/
    if [[ "${PLATFORM}" =~ "mp" ]] ; then
      echo "copy ST platform bootloader"
      cp ${SRC_BASE}/tf-a-${PLATFORM}-*.stm32 ${DEST_PATH}/
      cp ${SRC_BASE}/fip-${PLATFORM}-*.bin ${DEST_PATH}/
    fi
  fi

  find "${DEST_PATH}" -type f -name "${IMAGE}*-${PLATFORM}.ext4.gz" -print -exec gzip -d {} +

#  find "${DEST_PATH}" -type f -name '${IMAGE}*-${PLATFORM}.ext4.gz' -print0 | xargs -0 gzip -d

  if prompt-yesno "Is this a ros2 project?" no; then
    echo "DEY AIO support ROS2 and we can publish ros2 image as well."
    echo "now change ros image name to dey-image-qtros"
    ISROS="yes"
    find "${DEST_PATH}" -type f -name "*qt-xwayland-humble*" -exec bash -c 'mv "$0" "${0/qt-xwayland-humble/qtros}"' {} \;
    find "${DEST_PATH}" -type f -name "*qt-wayland-humble*" -exec bash -c 'mv "$0" "${0/qt-wayland-humble/qtros}"' {} \;
  else
    echo "use normal dey images for packing"
    ISROS="no"
#    find . -type f -name "*-humble*" -exec bash -c 'mv "$0" "${0/-humble/ros}"' {} \;
  fi

#  if [ -e ${DEST_PATH}/${IMAGE}-${PLATFORM}.ext4.gz ]; then
#    gzip -d ${DEST_PATH}/${IMAGE}-${PLATFORM}.ext4.gz
#  fi

# copy developping dtb
#  if [ "" != "${PROJECT}" ]; then
#    cp ${SRC_DTB}/imx6ul-${PLATFORM}-${PROJECT}*.dtb* ${DEST_PATH}/
#  fi

  echo "major images have been copied to release path"

  if prompt-yesno "Do you want to pack images to create an installer zip file?" yes; then
    sync
    sleep 2
    if [[ "${ISROS}" == "yes" ]]; then
      find "${DEST_PATH}" -type f \( -name 'dey-image-qtros*' -o -name 'install_*' -o -name 'imx*' -o -name 'meta*' -o -name 'tf*' -o -name 'fip*' -o -name 'u-boot*' -o -name 'boot.scr' \) -a \( ! -name '*.zip' \) -exec zip -j "${DEST_PATH}/${PROJECT}_sd_installer.zip" {} +
#    zip -j ${DEST_PATH}/${PROJECT}_sd_installer.zip ${DEST_PATH}/* -x ${DEST_PATH}/${PROJECT}_sd_installer.zip
    else
      find "${DEST_PATH}" -type f \( -name "${IMAGE}*" -o -name 'install_*' -o -name 'imx*' -o -name 'meta*' -o -name 'tf*' -o -name 'fip*' -o -name 'u-boot*' -o -name 'boot.scr' \) -a \( ! -name '*.zip' ! -name 'dey-image-qtros*' ! -name '*humble*' \) -exec zip -j "${DEST_PATH}/${PROJECT}_sd_installer.zip" {} +
    fi
  fi
else
  echo "you've chosen not to copy images to release folder! Make sure release folder already have the latest one. "
  echo "publishing to web/tftp will base on the images and zip files that are in release folder"
fi

if [[ -d "${SRC_SDK}" ]]; then
  if prompt-yesno "Copy SDK to release?" no; then
    cp -r ${SRC_SDK} ${DEST_PATH}/
  else
    echo "SDK won't copy out to release folder"
  fi
fi

if prompt-yesno "Would you like to publish the releases to the web/tftp server?" "no"; then
    echo "It can be a local path or remote one. Scripts will help you rsync the released stuff. "
    echo "A valid path should like: "
    echo "/home/mypath,10.10.1.10:/home/mypath or user@192.168.1.10:/home/mypath"
    PUBLISH_PATH=$(prompt "Please input the path:" "${DEST_PATH}/tftpboot")

    if [[ $PUBLISH_PATH =~ ^/ ]]; then
        echo "sync to local path：$PUBLISH_PATH"
        rsync -av --progress "$DEST_PATH" "$PUBLISH_PATH/"
    # judge if it's a remote path
    elif [[ $PUBLISH_PATH =~ ^[a-zA-Z0-9]+@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/ ]] || [[ $PUBLISH_PATH =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/ ]]; then
        # get user name and host
        if [[ $PUBLISH_PATH =~ ^[a-zA-Z0-9]+@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/ ]]; then
            user=$(echo "$PUBLISH_PATH" | cut -d '@' -f 1)
            host=$(echo "$PUBLISH_PATH" | cut -d '@' -f 2 | cut -d ':' -f 1)
        else
            # use local user if no user in the remote path 
            user=$(whoami)
            host=$(echo "$PUBLISH_PATH" | cut -d ':' -f 1)
            echo "no user specified in the remote path. use local user: $user"
        fi

        # prompt password input 
        read -sp "Please input password of the user to access remote server （or press enter in no password or use ssh key）： " password

        if [[ -n "$password" ]]; then
            sshpass -p "$password" rsync -avz --progress -e "ssh" "$DEST_PATH" "$PUBLISH_PATH"
        else
            rsync -avz --progress -e "ssh" "$DEST_PATH" "$PUBLISH_PATH"
        fi
    else
        echo "invalid path！"
        exit 1
    fi
fi


}
_ "$0" "$@"
