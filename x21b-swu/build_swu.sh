#!/usr/bin/bash

rm -r swu
mkdir swu
cd swu

cp ../config/sw-description .
cp ../../rockdev/uboot.img .
cp ../../rockdev/boot.img .
cp ../../rockdev/rootfs.img .

printf '%s\n' sw-description uboot.img boot.img rootfs.img | cpio -ov -H crc -L > update.swu
