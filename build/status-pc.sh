#!/bin/bash

while true; do
    # CPU usage (icon: )
    cpu="  $(top -bn1 | grep '%Cpu(s)' | awk '{printf "%02d%%", int($2+$4+$6+0.5)}')"
    
    # CPU temperature (icon: use one, comment out the other as needed)
    # For desktop PC:
    cputemp=" $(sensors | grep 'Tctl' | awk '{temp = int(substr($2, 2) + 0.5); printf "%02d°C", temp}')"
    
    # Nvidia GPU usage (icon: )
    gpu="   $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader | awk '{printf "%02d%%", $1}')"
    
    # Nvidia GPU temperature
    gputemp=" $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | awk '{print sprintf("%02.0f°C", $1)}')"
    
    # RAM usage (icon: )
    mem="   $(top -bn1 | grep 'MiB Mem' | awk '{used=$8; total=$4; printf "%02d%%", int((used/total)*100 + 0.5)}')"
    
    # Date/time (icon: 󰥔)
    datetime=" 󰥔  $(date '+%H:%M %-d %B %Y')"
    
    # Combine all segments
    status="$cpu$cputemp $gpu$gputemp $mem $datetime"
    
    # Set the status bar
    xsetroot -name "$status"
    
    # Wait 60 seconds
    sleep 60
done
