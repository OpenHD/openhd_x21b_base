#!/bin/sh
set -e

mnt="/tmp/sd_mnt"

cleanup() {
    umount "$mnt" 2>/dev/null || true
}

trap cleanup EXIT

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

    /usr/bin/update.sh "$file"

    rm -f "$file"

    cleanup
    trap - EXIT

    reboot
else
    echo "No update file found"
fi