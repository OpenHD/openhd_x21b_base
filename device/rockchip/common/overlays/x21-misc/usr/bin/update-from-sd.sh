#!/bin/sh
set -e

if [ ! -b /dev/mmcblk1p1 ]; then
    echo "Exit update early, no SD card detcted"
    exit 0
fi

mnt="/tmp/sd_mnt"

cleanup() {
    umount "$mnt" 2>/dev/null || true
}

trap cleanup EXIT

led_pet() {
    while true
    do
        ohdledctl /dev/ttyS3 pet-periodic
        sleep 2
    done
}

mkdir -p "$mnt"
mount /dev/mmcblk1p1 "$mnt"

file=""

for candidate in "$mnt"/*.ohd_base "$mnt"/*.ohd; do
    if [ -e "$candidate" ]; then
        file="$candidate"
        break
    fi
done

if [ -n "$file" ]; then
    echo "Found update file: $file"

    led_pet&
    ohdledctl /dev/ttyS3 breathe 0 0 255 1200 0 0 0 1200
    set +e
    pkill -f -9 openhd
    /usr/bin/update.sh "$file"
    rc=$?
    set -e

    if [ "$rc" -eq 0 ]; then
        ohdledctl /dev/ttyS3 breathe 0 0 255 1200 0 255 0 1200
    else
        ohdledctl /dev/ttyS3 breathe 0 0 255 1200 255 0 0 1200
    fi
    rm -f "$file"
    sleep 5

    cleanup
    trap - EXIT

    reboot
else
    echo "No update file found"
    cleanup
    trap - EXIT
    mount /dev/mmcblk1p1 /Video
fi