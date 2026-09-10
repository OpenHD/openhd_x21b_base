#!/bin/sh
set -eu

# A compact UBI image does not cover the complete 100 MiB NAND partition.
# Remove every old eraseblock first; otherwise stale UBI image-sequence
# headers beyond the new image make ubiattach reject the entire partition.
if [ "${1:-}" = "preinst" ]; then
    umount /ohd 2>/dev/null || true
    ubidetach /dev/ubi_ctrl -m 9 2>/dev/null || true
    flash_erase /dev/mtd9 0 0
fi
