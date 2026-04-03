#!/bin/sh
set -e

printf "Setting slot good"
cmdline="$(cat /proc/cmdline)"
root_dev=""
for arg in $cmdline; do
    case "$arg" in
        root=*)
            root_dev="${arg#root=}"
            ;;
    esac

echo "Rootdevice is $root_dev"
if [[ "$root_dev" == "/dev/mtdblock7" ]]; then
    new_slot="b"
else
    new_slot="a"
fi
echo "Updating slot: $new_slot"

if [[ "$new_slot" == "a" ]]; then
    swupdate -i $1 -n -e stable,slot-a
else
    swupdate -i $1 -n -e stable,slot-b
fi

echo "Done updating, switching slot"

if [[ "$new_slot" == "a" ]]; then
    slotcfg set /dev/mtd6 a 255 255
else
    slotcfg set /dev/mtd6 b 255 255
fi

echo "Update done, rebooting"
reboot