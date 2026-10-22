#!/bin/bash
set -euo pipefail

rootfs_dir="$(realpath "${1:?missing rootfs dir}")"
sdk_dir="$(realpath "${RK_SDK_DIR:-${rootfs_dir}/../../../..}")"
store_dir="${sdk_dir}/output/ohd-bundle"
dest_dir="${sdk_dir}/output/extra-parts/ohd"
overlay_dir="${sdk_dir}/ohd-misc"
test -d "${overlay_dir}"
mkdir -p "${sdk_dir}/output"
stage_dir="$(mktemp -d "${sdk_dir}/output/.ohd-bundle.XXXXXX")"
trap 'rm -rf "${stage_dir}"' EXIT

# Incremental builds may reuse known installed files, never a writable board
# partition with saved settings, SSH keys, captures or diagnostics.
for rel in usr/bin/openhd usr/bin/openhd_sys_utils \
           etc/init.d/S99openhd etc/init.d/S98openhd-sysutils; do
    source_file="${rootfs_dir}/${rel}"
    test -e "${source_file}" || source_file="${store_dir}/${rel}"
    if test -e "${source_file}"; then
        mkdir -p "${stage_dir}/$(dirname "${rel}")"
        cp -a "${source_file}" "${stage_dir}/${rel}"
    fi
done
test -x "${stage_dir}/usr/bin/openhd"
test -x "${stage_dir}/usr/bin/openhd_sys_utils"
mkdir -p "${stage_dir}/usr/lib"
shopt -s nullglob
for family in 'libPocoFoundation.so*' 'libPocoNet.so*' 'libPocoEncodings.so*' \
              'libpcap.so*' 'libsodium.so*' 'libusb-1.0.so*' \
              'librtlsdr.so*' 'librockchip_mpp.so*'; do
    matches=("${rootfs_dir}/usr/lib/"${family})
    if ((${#matches[@]} == 0)); then
        matches=("${store_dir}/usr/lib/"${family})
    fi
    ((${#matches[@]})) || { echo "Missing OHD runtime family: ${family}" >&2; exit 1; }
    cp -a "${matches[@]}" "${stage_dir}/usr/lib/"
done
for family in 'libncurses*.so*' 'libtinfo.so*' 'libform*.so*'; do
    matches=("${rootfs_dir}/usr/lib/"${family})
    ((${#matches[@]} == 0)) || cp -a "${matches[@]}" "${stage_dir}/usr/lib/"
done
if test -d "${rootfs_dir}/usr/share/terminfo"; then
    mkdir -p "${stage_dir}/usr/share"
    cp -a "${rootfs_dir}/usr/share/terminfo" "${stage_dir}/usr/share/"
fi
cp -a "${overlay_dir}/." "${stage_dir}/"
mkdir -p "${stage_dir}/ohd-rw" "${stage_dir}/ohd-config"
test -x "${stage_dir}/start-ohd.sh"

# Only these fixed, disposable SDK output paths are replaced.
rm -rf "${store_dir}" "${dest_dir}"
mv "${stage_dir}" "${store_dir}"
trap - EXIT
mkdir -p "${dest_dir}"
cp -a "${store_dir}/." "${dest_dir}/"
# Libraries remain in the base system for its tools. S99ohd is the single
# production application entry point, so remove duplicate rootfs launchers.
rm -f "${rootfs_dir}/usr/bin/openhd" "${rootfs_dir}/usr/bin/openhd_sys_utils" \
      "${rootfs_dir}/etc/init.d/S99openhd" "${rootfs_dir}/etc/init.d/S98openhd-sysutils"
