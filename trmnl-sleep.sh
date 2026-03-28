#!/system/bin/sh
UPTIME_MS=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
UPTIME_MS="${UPTIME_MS}000"
service call power 2 i32 $UPTIME_MS i32 0
