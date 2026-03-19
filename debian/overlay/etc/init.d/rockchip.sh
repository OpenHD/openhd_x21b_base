#!/bin/bash -e
### BEGIN INIT INFO
# Provides:          rockchip
# Required-Start:
# Required-Stop:
# Default-Start:
# Default-Stop:
# Short-Description:
# Description:       Setup rockchip platform environment
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# first boot configure
if [ ! -e "/usr/local/first_boot_flag" ]; then
    echo "It's the first time booting. The rootfs will be configured."

    # Force rootfs synced
    mount -o remount,sync /

    setcap CAP_SYS_ADMIN+ep /usr/bin/gst-launch-1.0

    if [ -e "/dev/rfkill" ]; then
        rm /dev/rfkill
    fi

    touch /usr/local/first_boot_flag

    # In order to achieve better compatibility, various applications will being
    # installed during the first system startup. This can result in slow boot times,
    # slow read/write speeds, and issues such as PipeWire audio being silent.
    sync
    shutdown -r now
fi

# sync system time
hwclock --systohc
