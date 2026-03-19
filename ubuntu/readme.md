## Introduction

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## Available Distro

* Ubuntu 22.04 (Jammy-X11 and Wayland)~~


## Usage for 32bit Debian 11 (Bullseye-32)
```
	Do not support this feature.
```

## Usage for 64bit Debian 11 (Bullseye-64)

Building a base ubuntu 22.04 system.

```
	VERSION=debug ARCH=arm64 ./mk-rootfs-jammy.sh
```

---

## Cross Compile for ARM Debian

[Docker + Multiarch](http://opensource.rock-chips.com/wiki_Cross_Compile#Docker)

## Package Code Base

Please apply [those patches](https://github.com/rockchip-linux/rk-rootfs-build/tree/master/packages-patches) to release code base before rebuilding!

## FAQ

mounted with noexec or nodev

Solution: mount -o remount,exec,dev xxx (xxx is the mount place), then rebuild it.
