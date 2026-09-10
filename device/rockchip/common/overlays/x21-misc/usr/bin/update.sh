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