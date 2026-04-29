#!/bin/bash -e

POST_ROOTFS_ONLY=1

source "${RK_POST_HELPER:-$(dirname "$(realpath "$0")")/post-helper}"

build_rtl88x2eu()
{
	check_config RK_KERNEL || return 0
	source "$RK_SCRIPTS_DIR/kernel-helper"

	MODULE_DIR="$RK_SDK_DIR/external/ohd-wifi-kernel/rtl88x2eu"

	[ -d "$MODULE_DIR" ] || {
		error "Module dir not found: $MODULE_DIR"
		exit 1
	}

	message "=========================================="
	message "        Building ohd kernel modules"
	message "=========================================="

	cd "$RK_SDK_DIR"

	if [ ! -r kernel/include/generated/asm-offsets.h ]; then
		notice "Kernel is not ready, building it first..."
		"$RK_SCRIPTS_DIR/mk-kernel.sh"
	fi

	$KMAKE M="$MODULE_DIR" CONFIG_RTL8822EU=m modules

	mkdir -p "$RK_SDK_DIR/output/ohd-bundle/drivers/"
	cp "$MODULE_DIR/88x2eu_ohd.ko" "$RK_SDK_DIR/output/ohd-bundle/drivers/";
}

message "Building rtl88x2eu module..."
cd "$RK_SDK_DIR"
build_rtl88x2eu