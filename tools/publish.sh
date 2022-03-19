#! /bin/bash
#This scripts help you pack your release image files to DEY release folder
#check out https://github.com/peyoot/dey-aio for more informaiton
 
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
DEY_VERSION=$(pwd |awk -F '/' '{print $(NF-1)}')

#check if any git repository avaialbe in workspace
if [ ! -d .git ]; then
    WORKSPACE_GIT="no"
    echo "Your workspace do not have any branch now! A workspace git repository will facilitate you on revision management"

else
    WORKSPACE_GIT="yes"
    BRANCH=$(git status |head -1 | awk '{ print $3 }')
#    PLATFORM_SHORT=${BRANCH%-*}
fi
# Automatically check projects in workspace 
echo "Try to find out your projects in workspace"
PLIST=( $(ls -l |grep -E '^d'|grep cc | awk '{print $9}') )
#    echo "${PLIST[@]}"
#    echo ${#PLIST[*]}
NUM=${#PLIST[@]}
echo "Please select the hardware platform you are about to publish:"
for ((i=0;i<$NUM;i++)); do
  j=$((i+1))
  echo "${j} ${PLIST[${i}]}"
done
PLATFORM_SELECTOR=$(prompt-numeric "Which one you are going to publish" "1")
if [ ${PLATFORM_SELECTOR} -le ${NUM} ]; then
  PLATFORM=${PLIST[((PLATFORM_SELECTOR-1))]}
  echo "platform in array selected is ${PLATFORM}"
else
  echo "please input the number within options.Abort now!"
  exit 1
fi

#image type selection
echo "Please choose the  image type you're about to publish"
echo "1. dey-image-qt"
echo "2. core-image-base"
echo "3. dey-image-tiny"
IMAGE_SELECTOR=$(prompt-numeric "which kind of image you're going to publish" "1")
if [ "1" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-qt-${XSERVER}"
elif [ "2" = "$IMAGE_SELECTOR" ]; then
  IMAGE="core-image-base"
elif [ "3" = "$IMAGE_SELECTOR" ]; then
  IMAGE="dey-image-tiny"
else
  echo "please input the right choice"
  exit 1
fi

# preprare copy to release

SRC_BASE="${PLATFORM}/tmp/deploy/images/${PLATFORM}"
if [ "no" = "$WORKSPACE_GIT" ]; then
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
  cp ${SRC_BASE}/u-boot.imx ${DEST_PATH}/
  cp ${SRC_BASE}/u-boot-ccimx6ulsbc512MB.imx ${DEST_PATH}/
  cp ${SRC_BASE}/u-boot-ccimx6ulsbc1GB.imx ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.boot.ubifs ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.recovery.ubifs ${DEST_PATH}/
  cp ${SRC_BASE}/${IMAGE}-${PLATFORM}.ubifs ${DEST_PATH}/
#  cp ${SRC_DTB}/imx6ul-${PLATFORM}*.dtb ${DEST_PATH}/
  cp ${SRC_BASE}/install_linux* ${DEST_PATH}/
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
