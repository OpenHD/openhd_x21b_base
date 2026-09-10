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
    local package_files=(sw-description)

    for img in "${images[@]}"; do
        cp "$ROCKDEV/$img" "$work/$img"
        if [ "$img" = "ohd.img" ]; then
            # SWUpdate 2023.12 erases only the input image length on NAND.
            # Extend the compact UBI image with erased pages to cover all of
            # the 100 MiB OHD partition and remove stale image-sequence headers.
            ohd_partition_size=$((0x6400000))
            ohd_image_size="$(stat -c '%s' "$work/$img")"
            if ((ohd_image_size > ohd_partition_size)); then
                echo "OHD image is larger than mtd9" >&2
                exit 1
            fi
            head -c "$((ohd_partition_size - ohd_image_size))" /dev/zero \
                | tr '\000' '\377' >> "$work/$img"
        fi
        package_files+=("$img")
    done

    (
        cd "$work"
        printf '%s\n' "${package_files[@]}" | cpio -ov -H crc -L > "../$output"
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
