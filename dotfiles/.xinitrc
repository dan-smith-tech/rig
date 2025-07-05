xset s off
xset -dpms
xset s noblank

xsetroot -mod 16 16 -fg "#222222" -bg "#111111" &
/usr/local/src/dwm/status.sh &
exec dwm
