#!/bin/bash

while true; do
    # CPU usage (icon: )
    cpu=" $(top -bn1 | grep '%Cpu(s)' | awk '{printf "%02d%%", int($2+$4+$6+0.5)}')"
    
    # CPU temperature (icon: use one, comment out the other as needed)
    cputemp=" $(sensors | grep 'Package id 0' | awk '{print int(substr($4, 2) + 0.5) "°C"}')"
    
    # RAM usage (icon: )
    mem="  $(top -bn1 | grep 'MiB Mem' | awk '{used=$8; total=$4; printf "%02d%%", int((used/total)*100 + 0.5)}')"
    
    # Battery (icon: ) -- only if on laptop
    battery=""
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        battery="  $(printf "%02d%%" $(cat /sys/class/power_supply/BAT0/capacity))"
    fi
    
    # Date/time (icon: 󰥔)
    datetime=" 󰥔 $(date '+%H:%M %-d %B %Y')"
    
    # Combine all segments
    status="$cpu $cputemp $mem $battery $datetime"
    
    # Set the status bar
    xsetroot -name "$status"
    
    # Wait 60 seconds
    sleep 60
done
