#!/bin/bash
while true; do
    cpu="  $(top -bn1 | grep '%Cpu(s)' | awk '{printf "%02d%%", int($2+$4+$6+0.5)}')"
    cputemp="$(sensors | grep 'Package id 0' | awk '{print int(substr($4, 2) + 0.5) "°C"}')"
    mem="  $(top -bn1 | grep 'MiB Mem' | awk '{used=$8; total=$4; printf "%02d%%", int((used/total)*100 + 0.5)}')"
    battery=""
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        battery="  $(printf "%02d%%" $(cat /sys/class/power_supply/BAT0/capacity))"
    fi
    datetime="󰥔  $(date '+%H:%M %-d %B %Y')"
    echo "$cpu $cputemp  $mem  $battery  $datetime"
    sleep 5
done
