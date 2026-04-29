#!/bin/bash -e

build_rtl88x2eu()
{
	DEFAULT_ROOTFS_DIR="$RK_OUTDIR/rootfs/target"
	ROOTFS_DIR="${1:-$DEFAULT_ROOTFS_DIR}"

	if [ ! -d "$ROOTFS_DIR" ]; then
		error "$ROOTFS_DIR is not a dir!"
		return 1
	fi

	"$RK_SCRIPTS_DIR/post-ohd-wifi.sh" "$(realpath "$ROOTFS_DIR")" \
		$([ -r "$ROOTFS_DIR/etc/os-release" ] || echo buildroot)

	finish_build build_rtl88x2eu "$@"
}

# Hooks

usage_hook()
{
	usage_oneline "rtl88x2eu[:<dst dir>]" "build rtl88x2eu wifi module"
}

BUILD_CMDS="rtl88x2eu"
build_hook()
{
	shift
	build_rtl88x2eu "$@"
}

source "${RK_BUILD_HELPER:-$(dirname "$(realpath "$0")")/build-helper}"

build_rtl88x2eu "$@"