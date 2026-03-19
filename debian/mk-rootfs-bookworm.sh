#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

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

echo -e "\033[36m Building for $VERSION \033[0m"

if [ ! -e linaro-bookworm-alip-*.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
	exit -1
fi

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf linaro-bookworm-alip-*.tar.gz

# packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rpf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

# overlay folder
sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
	sudo cp -rpf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

echo -e "\033[36m Change root.....................\033[0m"

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

# Fixup owners
if [ "$ID" -ne 0 ]; then
       find / -user $ID -exec chown -h 0:0 {} \;
fi
for u in \$(ls /home/); do
	chown -h -R \$u:\$u /home/\$u
done

echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 127.0.0.53" >> /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

echo "deb http://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib" >> /etc/apt/sources.list
echo "deb-src http://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib" >> /etc/apt/sources.list

apt-get update
apt-get upgrade -y

export APT_INSTALL="apt-get install -fy --allow-downgrades"

# enter root username without password
sed -i "s~\(^ExecStart=.*\)~# \1\nExecStart=-/bin/sh -c '/bin/bash -l </dev/%I >/dev/%I 2>\&1'~" /usr/lib/systemd/system/serial-getty@.service

#---------------power management --------------
sed -i "s/#HandlePowerKey=.*/HandlePowerKey=ignore/" /etc/systemd/logind.conf

#---------------Rga--------------
\${APT_INSTALL} /packages/rga2/*.deb

echo -e "\033[36m Setup Video.................... \033[0m"
\${APT_INSTALL} /packages/mpp/*
\${APT_INSTALL} /packages/gst-rkmpp/*.deb
\${APT_INSTALL} /packages/gstreamer/*.deb
\${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb

#---------Camera---------
echo -e "\033[36m Install camera.................... \033[0m"
\${APT_INSTALL} /packages/libv4l/*.deb
\${APT_INSTALL} /packages/cheese/*.deb
\${APT_INSTALL} /packages/rkaiq/*.deb

#---------Xserver---------
echo -e "\033[36m Install Xserver.................... \033[0m"
\${APT_INSTALL} /packages/xserver/*.deb

apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy

#---------Wayland/Weston---------
echo -e "\033[36m Install Wayland/Weston.................... \033[0m"
\${APT_INSTALL} libseat-dev
\${APT_INSTALL} /packages/weston/*.deb
\${APT_INSTALL} /packages/wayland/*.deb

#---------------Openbox--------------
echo -e "\033[36m Install openbox.................... \033[0m"
\${APT_INSTALL} /packages/openbox/*.deb

#---------------pcmanfm--------------
echo -e "\033[36m Install pcmanfm.................... \033[0m"
\${APT_INSTALL} /packages/pcmanfm/*.deb

#------------------libdrm------------
echo -e "\033[36m Install libdrm.................... \033[0m"
\${APT_INSTALL} /packages/libdrm/*.deb

#------------------libdrm-cursor------------
echo -e "\033[36m Install libdrm-cursor.................... \033[0m"
\${APT_INSTALL} /packages/libdrm-cursor/*.deb

#------------------blueman------------
echo -e "\033[36m Install blueman.................... \033[0m"
\${APT_INSTALL} blueman
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
\${APT_INSTALL} blueman
rm -f /usr/sbin/policy-rc.d

#------------------blueman------------
echo -e "\033[36m Install blueman.................... \033[0m"
\${APT_INSTALL} /packages/blueman/*.deb

if [ "$VERSION" == "debug" ]; then
#------------------glmark2------------
echo -e "\033[36m Install glmark2.................... \033[0m"
\${APT_INSTALL} /packages/glmark2/*.deb
fi

if [ -e "/usr/lib/aarch64-linux-gnu" ] ;
then
#------------------rknpu2------------
echo -e "\033[36m install rknpu2.................... \033[0m"
[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /packages/rknpu2/rknpu2.tar -C /
fi

#------------------pipewire------------
echo -e "\033[36m Install pipewire.................... \033[0m"
\${APT_INSTALL} /packages/pipewire/*.deb
\${APT_INSTALL} /packages/wireplumber/*.deb
find /usr/lib/systemd/ -name "wireplumber*.service" | xargs sed -i "/Environment/s/$/ DISPLAY=:0/"

#--------------------weston/wayland------------
\${APT_INSTALL} /packages/weston/*.deb
\${APT_INSTALL} /packages/wayland/*.deb

# reduce 500M size for rootfs
rm -rf /usr/lib/firmware

# mark package to hold
apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

#---------------disable services---------
systemctl disable console-setup.service usbdevice.service keyboard-setup.service blueman-mechanism.service e2scrub_reap.service \
bootanim.service

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------Clean--------------
if [ -e "/usr/lib/arm-linux-gnueabihf/dri" ] ;
then
        # Only preload libdrm-cursor for X
        sed -i "1aexport LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libdrm-cursor.so.1" /usr/bin/X
        cd /usr/lib/arm-linux-gnueabihf/dri/
        cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
        rm /usr/lib/arm-linux-gnueabihf/dri/*.so
        mv /*.so /usr/lib/arm-linux-gnueabihf/dri/
elif [ -e "/usr/lib/aarch64-linux-gnu/dri" ];
then
        # Only preload libdrm-cursor for X
        sed -i "1aexport LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libdrm-cursor.so.1" /usr/bin/X
        cd /usr/lib/aarch64-linux-gnu/dri/
        cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
        rm /usr/lib/aarch64-linux-gnu/dri/*.so
        mv /*.so /usr/lib/aarch64-linux-gnu/dri/
        rm /etc/profile.d/qt.sh
fi
cd -

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/

EOF
