xset s off
xset -dpms
xset s noblank

xsetroot -solid "#282936" &
/usr/local/src/dwm/status.sh &
exec dwm
