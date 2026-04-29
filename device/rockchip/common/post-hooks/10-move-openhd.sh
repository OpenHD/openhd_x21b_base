#!/bin/bash -e

ROOTFS_DIR="$1"
DEST_SUBDIR_STORE="../../../../output/ohd-bundle"
DEST_SUBDIR="../../../../output/extra-parts/ohd"
OVERLAY_SUBDIR="../../../../ohd-misc"

[ -n "$ROOTFS_DIR" ] || {
    echo "missing rootfs dir"
    exit 1
}

STORE_DIR="$ROOTFS_DIR/$DEST_SUBDIR_STORE"
DEST_DIR="$ROOTFS_DIR/$DEST_SUBDIR"
OVERLAY_DIR="$ROOTFS_DIR/$OVERLAY_SUBDIR"

FILES_TO_MOVE="
usr/bin/openhd
usr/bin/openhd_sys_utils
usr/lib/libpcap.so
usr/lib/libpcap.so.1
usr/lib/libpcap.so.1.10.4
usr/lib/libsodium.so
usr/lib/libsodium.so.23
usr/lib/libsodium.so.23.3.0W
usr/lib/libPocoEncodings.so
usr/lib/libPocoEncodings.so.102
usr/lib/libPocoNet.so
usr/lib/libPocoNet.so.102
usr/lib/libPocoFoundation.so
usr/lib/libPocoFoundation.so.102
etc/init.d/S99openhd
etc/init.d/S98openhd-sysutils
"

mkdir -p "$STORE_DIR"
mkdir -p "$DEST_DIR"

echo "Storing OpenHD files into: $STORE_DIR"

for rel in $FILES_TO_MOVE; do
    src="$ROOTFS_DIR/$rel"
    store="$STORE_DIR/$rel"

    if [ -e "$src" ] || [ -L "$src" ]; then
        mkdir -p "$(dirname "$store")"
        mv "$src" "$store"
        echo "stored: $rel"
    else
        echo "skip missing: $rel"
    fi
done

echo "Copying OpenHD files into final dir: $DEST_DIR"

for rel in $FILES_TO_MOVE; do
    store="$STORE_DIR/$rel"
    dst="$DEST_DIR/$rel"

    if [ -e "$store" ] || [ -L "$store" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$store" "$dst"
        echo "copied: $rel"
    else
        echo "skip missing in store: $rel"
    fi
done

cp -a "$OVERLAY_DIR"/. "$STORE_DIR"/

exit 0