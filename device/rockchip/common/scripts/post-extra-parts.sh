#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${RK_POST_HELPER:-$(dirname "$(realpath "$0")")/post-helper}"

message "Preparing extra partitions..."

for idx in $(seq 1 "$(rk_extra_part_num)"); do
	MOUNTPOINT="$(rk_extra_part_mountpoint $idx)"
	FAKEROOT_SCRIPT="$(rk_extra_part_fakeroot_script $idx)"
	OUTDIR="$(rk_extra_part_outdir $idx)"
	MOUNT_DIR="$(rk_extra_part_mount_dir $idx)"

	rm -rf "$FAKEROOT_SCRIPT" "$OUTDIR" "$MOUNT_DIR"
	mkdir -p "$TARGET_DIR/$MOUNTPOINT" "$(dirname "$MOUNT_DIR")"
	ln -rsf "$TARGET_DIR/$MOUNTPOINT" "$MOUNT_DIR"

	if [ "$MOUNTPOINT" = "/ohd" ] || [ "$MOUNTPOINT" = "ohd" ]; then
		OHD_STORE_DIR="$TARGET_DIR/../../../../output/ohd-bundle"
		if [ -d "$OHD_STORE_DIR" ]; then
			message "Restoring OHD bundle from $OHD_STORE_DIR to $OUTDIR"
			mkdir -p "$OUTDIR"
			rsync -a "$OHD_STORE_DIR"/ "$OUTDIR"/
		fi
	fi

	if rk_extra_part_builtin $idx; then
		rk_extra_part_prepare $idx
		message "Merging $OUTDIR into $TARGET_DIR/$MOUNTPOINT (built-in)"
		rsync -a "$OUTDIR/" "$TARGET_DIR/$MOUNTPOINT/"
	fi
done
