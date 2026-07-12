#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%d%m%Y)"
OUTDIR="swu"
ROCKDEV="../rockdev"
CONFIG="config"

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

make_package() {
    local desc="$1"
    local output="$2"
    shift 2
    local images=("$@")

    local work="$OUTDIR/$output.tmp"

    rm -rf "$work"
    mkdir -p "$work"

    cp "$CONFIG/$desc" "$work/sw-description"

    for img in "${images[@]}"; do
        cp "$ROCKDEV/$img" "$work/$img"
    done

    (
        cd "$work"
        printf '%s\n' sw-description "${images[@]}" | cpio -ov -H crc -L > "../$output"
    )

    rm -rf "$work"
    echo "Created: $OUTDIR/$output"
}

# Slotless OHD-only update: does NOT switch slot
make_package \
    "sw-description-ohd" \
    "OpenHD-X21B-${DATE}.ohd" \
    ohd.img

# Base A/B update: switches slot
make_package \
    "sw-description-base" \
    "OpenHD-X21B-${DATE}.ohd_base" \
    uboot.img boot.img rootfs.img

# Full A/B + shared OHD update: switches slot
make_package \
    "sw-description-full" \
    "OpenHD-X21B-full-${DATE}.ohd_base" \
    ohd.img uboot.img boot.img rootfs.img