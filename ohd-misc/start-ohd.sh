#!/bin/bash

# This is OHD helper on x21b, this script is the entry point of "ohd-bundle" part of system, its loaded by base system and should handle ohd tasks

OHD_LOG_FILE="/var/log/openhd.log"
OHD_PID_FILE="/var/run/openhd.pid"
OHD_SYSUTILS_LOG_FILE="/var/log/openhd-sys-utils.log"
OHD_SYSUTILS_PID_FILE="/var/run/openhd-sys-utils.pid"


# Use ohd-side libs
export LD_LIBRARY_PATH=/ohd/usr/lib:$LD_LIBRARY_PATH

# Bind mount ohd-rw, as base system is RO
mount --bind /ohd/ohd-rw /usr/local/share/openhd
mount --bind /ohd/ohd-config /Config

# Load drivers
insmod /ohd/drivers/88x2eu_ohd.ko

# Start sysuitls
nohup /ohd/usr/bin/openhd_sys_utils >> "$OHD_SYSUTILS_LOG_FILE" 2>&1 &
echo $! > "$OHD_SYSUTILS_PID_FILE"
echo "OpenHD-sysutils started successfully with PID $(cat $OHD_SYSUTILS_PID_FILE)!" | tee -a "$OHD_SYSUTILS_LOG_FILE"

# Start ohd
nohup /ohd/usr/bin/openhd -a >> "$OHD_LOG_FILE" 2>&1 &
echo $! > "$OHD_PID_FILE"
echo "OpenHD started successfully with PID $(cat $OHD_PID_FILE)!" | tee -a "$OHD_LOG_FILE"
