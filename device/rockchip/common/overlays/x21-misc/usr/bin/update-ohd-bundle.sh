#!/bin/sh
set -eu

bundle="${1:-}"
ohd_root="/ohd"
stage="${ohd_root}/.update-stage"
previous="${ohd_root}/.update-previous-usr"

fail() {
    echo "X21B application update failed: $*" >&2
    exit 1
}

[ -f "$bundle" ] || fail "bundle not found"

# Only accept the small, platform-specific archive layout produced by the
# OpenHD X21B bundle workflow. Reject absolute and parent-traversal paths
# before extracting as root.
tar -tf "$bundle" >"/tmp/ohd-bundle-files.$$" || fail "invalid tar archive"
if grep -Eq '(^/|(^|/)\.\.(/|$))' "/tmp/ohd-bundle-files.$$"; then
    rm -f "/tmp/ohd-bundle-files.$$"
    fail "unsafe path in bundle"
fi
rm -f "/tmp/ohd-bundle-files.$$"

rm -rf "$stage"
mkdir -p "$stage"
tar -xf "$bundle" -C "$stage" || fail "cannot extract bundle"

[ -f "$stage/manifest.json" ] || fail "manifest is missing"
grep -Eq '"platform"[[:space:]]*:[[:space:]]*"x21b"' "$stage/manifest.json" || \
    fail "bundle is not for X21B"
[ -f "$stage/sha256sums" ] || fail "payload checksums are missing"
(
    cd "$stage"
    sha256sum -c sha256sums
) || fail "payload checksum verification failed"
[ -x "$stage/usr/bin/openhd" ] || fail "OpenHD executable is missing"
[ -x "$stage/usr/bin/openhd_sys_utils" ] || fail "SysUtils executable is missing"

# Keep configuration, recordings and drivers in /ohd untouched. Retain the
# previous usr tree so recovery over ADB remains possible after a bad update.
rm -rf "$previous"
if [ -e "$ohd_root/usr" ]; then
    mv "$ohd_root/usr" "$previous" || fail "cannot preserve previous installation"
fi

if ! mv "$stage/usr" "$ohd_root/usr"; then
    [ ! -e "$ohd_root/usr" ] || rm -rf "$ohd_root/usr"
    [ ! -e "$previous" ] || mv "$previous" "$ohd_root/usr"
    fail "cannot activate new installation"
fi

cp "$stage/manifest.json" "$ohd_root/installed-bundle.json"
rm -rf "$stage"
sync
echo "X21B application update installed successfully"
