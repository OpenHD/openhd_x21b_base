#!/bin/sh
set -e

file="$1"

if [ -z "$file" ]; then
    echo "Usage: $0 <update-file>"
    exit 1
fi

case "$file" in
    *.ohd_base)
        switch_slot=1
        ;;
    *.ohd)
        switch_slot=0
        ;;
    *)
        echo "Unsupported update file extension: $file"
        echo "Expected .ohd_base or .ohd"
        exit 1
        ;;
esac

# The OHD UBI volume is mounted by S00mountall before S99ohd checks the SD
# card for updates. Never let SWUpdate's raw NAND handler erase mtd9 while UBI
# is still attached: the UBI background thread can rewrite erase-counter
# headers during the flash, leaving mixed image sequence numbers behind.
prepare_ohd_partition_for_update() {
    sync

    # These bind mounts may be active when an SD card is inserted after boot.
    for mountpoint in /usr/local/share/openhd /Config; do
        if grep -qs " $mountpoint " /proc/mounts; then
            umount "$mountpoint"
        fi
    done

    if grep -qs " /ohd " /proc/mounts; then
        umount /ohd
    fi

    if [ -d /sys/class/ubi/ubi9 ]; then
        ubidetach /dev/ubi_ctrl -m 9
    fi
}

prepare_ohd_partition_for_update

if [ "$switch_slot" = "0" ]; then
    echo "Running slotless update: $file"
    swupdate -i "$file"
    echo "Update done, not switching slot"
    exit 0
fi

cmdline="$(cat /proc/cmdline)"
root_dev=""

for arg in $cmdline; do
    case "$arg" in
        root=*)
            root_dev="${arg#root=}"
            ;;
    esac
done

echo "Root device is $root_dev"

if [ "$root_dev" = "/dev/mtdblock7" ]; then
    new_slot="b"
else
    new_slot="a"
fi

echo "Updating slot: $new_slot"

if [ "$new_slot" = "a" ]; then
    swupdate -i "$file" -e stable,slot-a
else
    swupdate -i "$file" -e stable,slot-b
fi

echo "Done updating, switching slot"

if [ "$new_slot" = "a" ]; then
    slotcfg set /dev/mtd6 a 255 255
else
    slotcfg set /dev/mtd6 b 255 255
fi

echo "Update done, please reboot"
