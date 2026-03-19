#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"
UBUNTU_VER=$1

case "${ARCH:-$1}" in
	arm|arm32|armhf)
		ARCH=armhf
		;;
	*)
		ARCH=arm64
		;;
esac

echo -e "\033[36m Building for $ARCH \033[0m"

if [ ! $VERSION ]; then
	VERSION="release"
fi

#
# create binary folder if not exist.
#
if [ ! -d $TARGET_ROOTFS_DIR ] ; then
    sudo mkdir -p $TARGET_ROOTFS_DIR
fi	

#
# extract ubuntu base tar package.
#
echo -e "\033[36m Extract image \033[0m"
sudo tar -zxvf ubuntu.base.$UBUNTU_VER.tar.gz  >> /dev/null
	
echo -e "\033[36m Mount base image \033[0m"	
sudo mount -o loop ubuntu-base-$UBUNTU_VER.img $TARGET_ROOTFS_DIR


finish() {
	echo -e "\033[36m Exit.....................\033[0m"
	sudo umount $TARGET_ROOTFS_DIR
	exit -1
}
trap finish ERR


echo -e "\033[36m append patches.....................\033[0m"

# overlay folder
sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

echo -e "\033[36m copy adbd.....................\033[0m"
# adb
#if [[ "$ARCH" == "armhf" && "$VERSION" == "debug" ]]; then
#	sudo cp -f overlay-debug/usr/local/share/adb/adbd-32 $TARGET_ROOTFS_DIR/usr/bin/adbd
#elif [[ "$ARCH" == "arm64" && "$VERSION" == "debug" ]]; then
#	sudo cp -f overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/bin/adbd
#fi

# bt/wifi firmware
#sudo find ../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
#    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/

echo  "Change root....................."

#sudo cp -f /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/

#sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

echo -e "\033[36m running arm64 quem....................\033[0m"

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

#apt-get update
#apt-get upgrade -y

#chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#chmod +x /etc/rc.local

export APT_INSTALL="apt-get install -fy --allow-downgrades"

#
# TODO: here, please add the target packages you want to install.
#       For example: \${APT_INSTALL} ttf-wqy-zenhei fonts-aenigma
#                    \${APT_INSTALL} xfonts-intl-chinese
#

echo -e "\033[36m Install Chinese fonts.................... \033[0m"
#sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
#echo "LANG=en_US.UTF-8" >> /etc/default/locale

# Generate locale
#locale-gen

# Export env vars
#echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
#echo "export LANG=en_US.UTF-8" >> ~/.bashrc
#echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

#source ~/.bashrc

#\${APT_INSTALL} ttf-wqy-zenhei fonts-aenigma
#\${APT_INSTALL} xfonts-intl-chinese


# mark package to hold
#apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold


# HACK to disable the kernel logo on bootup
#sed -i "/exit 0/i \ echo 3 > /sys/class/graphics/fb0/blank" /etc/rc.local


#---------------Clean--------------
rm -rf /var/lib/apt/lists/*
history -cw

exit

EOF

sudo umount $TARGET_ROOTFS_DIR
