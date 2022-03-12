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
else
    WORKSPACE_GIT="yes"
    BRANCH=$(git status |head -1 | awk '{ print $3 }')
    PLATFORM=${BRANCH%-*}
fi



echo "DEY version is ${DEY_VERSION}"
echo "BRANCH is ${BRANCH}"
echo "platform is ${PLATFORM}"

notexec() { # start block comments

echo "You are about to copy images that you just built to the release folder."
echo "Please choose DEY version"
echo "1. DEY 3.2"
echo "2. DEY 3.0"
DEY_VERSION=$(prompt-numeric "Which DEY version you're working on?" "2")
if [ "1" = "$DEY_VERSION" ]; then
   DEY="3.2"
else
   DEY="3.0"
fi
echo "DEY_VERSION"


BRANCH=master
if [ "$BRANCH" = "master" ]; then
    echo "You're at not in any branch now"
    echo "Please choose the platform that you're working on:"
    echo "1. ConnectCore 6UL"
    echo "2. ConnectCore 8M Nano"
    echo "3. ConnectCore 8x"
    PLATFORM=$(prompt-numeric "Which one you are going to copy release" "1")
    echo "Please choose the  image type you're about to copy:"
    echo "1. dey-image-qt"
    echo "2. core-image-base"
    echo "3. dey-image-tiny"
    IMAGE_TYPE=$(prompt-numeric "which kind of image you're going to publish" "1")

    if [ "1" =  "$PLATFORM" ]; then
        echo "Now copying cc6ul release"
        SOURCE_PATH="cc6ulsbc/tmp/deploy/images/ccimx6ulsbc"
        CPU="imx6ul"
        SBC="ccimx6ulsbc"
        KFS="ubifs"
        RFS="ubifs"
        XSERVER="x11"
        UBOOTPRE="u-boot"
        UBOOTEXT="imx"
    fi
    if [ "2" = "$PLATFORM" ]; then
        SOURCE_PATH="tmp/deploy/images/ccimx8mn-dvk"
        CPU="imx8mn"
        SBC="ccimx8mn-dvk"
        KFS="vfat"
        RFS="ext4"
        XSERVER="xwayland"
        UBOOTPRE="imx-boot"
        UBOOTEXT="bin"
    fi
    if [ "3" = "$PLATFORM" ]; then
        SOURCE_PATH="tmp/deploy/images/ccimx8x-sbc-pro"
        CPU="imx8x"
        SBC="ccimx8x-sbc-pro"
        KFS="vfat"
        RFS="ext4"
        XSERVER="xwayland"
        UBOOTPRE="imx-boot"
        UBOOTEXT="bin"
    fi

    if [ "1" = "$IMAGE_TYPE" ]; then
      IMAGE="dey-image-qt-${XSERVER}"
    elif [ "2" = "$IMAGE_TYPE" ]; then
      IMAGE="core-image-base"
    elif [ "3" = "$IMAGE_TYPE" ]; then
      IMAGE="dey-image-tiny"
    else
      echo "please input the right choice"
      exit 1
    fi
    DEST_PATH="release/cc${CPU}/${DEY}"
    if [ ! -d $DEST_PATH ]; then
        mkdir -p $DEST_PATH
    fi

    echo "you're about to copy  ${IMAGE} to publish folder"
#    cp ${SOURCE_PATH}/${IMAGE}-cc${CPU}sbc.boot.ubifs ${DEST_PATH}/
    cp ${SOURCE_PATH}/${IMAGE}-${SBC}.boot.${KFS} ${DEST_PATH}/
    cp ${SOURCE_PATH}/${IMAGE}-${SBC}.${RFS} ${DEST_PATH}/
    cp ${SOURCE_PATH}/${IMAGE}-${SBC}.recovery.${KFS} ${DEST_PATH}/
    cp ${SOURCE_PATH}/${UBOOTPRE}-${SBC}*.${UBOOTEXT} ${DEST_PATH}/
    cp ${SOURCE_PATH}/install_linux_fw_sd.scr ${DEST_PATH}/
    echo "....."
    echo "Successfully copy images from ${SOURCE_PATH} to release/cc${CPU}"
    if prompt-yesno "Do you want to pack images to create an installer zip file?" yes; then
        sync
        sleep 2
        zip -j ${DEST_PATH}/my_sd_installer.zip ${DEST_PATH}/${IMAGE}*.* ${DEST_PATH}/${UBOOTPRE}-${SBC}*.${UBOOTEXT} ${DEST_PATH}/install_linux_fw_sd.scr -x ${DEST_PATH}/my_sd_installer.zip
    fi

fi

if prompt-yesno "Would you like to publish the releases to the web/tftp server?" "no"; then
    echo "Please choose where you'd like publish:"
    echo "1. Publish to ./tftpboot"
    echo "2. Publish to dey-mirror"
    echo "3. Publish both to tftpboot and dey-mirror"
    PUBLISH=$(prompt-numeric "Please choose where you'd like to publish releases" "1")
    if [ "1" = "$PUBLISH" ]; then
       echo "copying the release to ./tftpboot"
       cp ${DEST_PATH}/${IMAGE}* ./tftpboot/
       cp ${DEST_PATH}/u-boot* ./tftpboot/
    elif [ "2" = "$PUBLISH" ]; then
       echo "copying the release to dey-mirror"
       USERNAME=$(prompt "Please input the username of dey-mirror server" "")
       if [ "robin" = "${USERNAME}" ]; then
         echo "you'll need to input correct password to authenticate yourself"
         rsync -avzP ${DEST_PATH}/*.zip '-e ssh -p 10022' robin@101.231.59.67:/home/robin/docker/dnmp/www/dey-mirror/dey-images/${DEST_PATH}/
       else
         echo "You don't have the right to access eccee server"
         exit 1
       fi
    elif [ "3" = "$PUBLISH" ]; then
       echo "copying the release both to tftp server and dey-mirror"
       cp ${DEST_PATH}/${IMAGE}* ./tftpboot/
       cp ${DEST_PATH}/${UBOOTPRE}* ./tftpboot/
       USERNAME=$(prompt "Please input the username of dey-mirror server" "")
       if [ "robin" = "${USERNAME}" ]; then
         echo "you'll need to input correct password to authenticate yourself"
         rsync -avzP ${DEST_PATH}/*.zip '-e ssh -p 10022' robin@101.231.59.67:/home/robin/docker/dnmp/www/dey-mirror/dey-images/${DEST_PATH}/
       else
         echo "You don't have the right to access eccee server"
         exit 1
       fi
    else
       echo "Please input the right choice"
       exit 1
    fi
fi

} #end block comments

}
_ "$0" "$@"
