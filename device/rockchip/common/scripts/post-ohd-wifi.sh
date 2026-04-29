#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${RK_POST_HELPER:-$(dirname "$(realpath "$0")")/post-helper}"

build_rtl88x2eu()
{
	check_config RK_KERNEL || return 0
	source "$RK_SCRIPTS_DIR/kernel-helper"

	message "=========================================="
	message "       Building rtl88x2eu wifi module"
	message "=========================================="

	MODULE_DIR="$RK_SDK_DIR/external/ohd-wifi-kernel/rtl88x2eu"

	if [ ! -d "$MODULE_DIR" ]; then
		error "Missing module directory: $MODULE_DIR"
		exit 1
	fi

	# Make sure kernel is prepared
	if [ ! -r kernel/include/generated/asm-offsets.h ]; then
		notice "Kernel is not ready, building it first..."
		"$RK_SCRIPTS_DIR/mk-kernel.sh"
	fi

	# Build module
	$KMAKE M="$MODULE_DIR" modules

	# Install module into rootfs
	mkdir -p "$TARGET_DIR/lib/modules/"
	find "$MODULE_DIR" -name '*.ko' -exec cp -v {} "$TARGET_DIR/lib/modules/" \;

	message "rtl88x2eu build done"
}

message "Building rtl88x2eu module..."
cd "$RK_SDK_DIR"
build_rtl88x2eu