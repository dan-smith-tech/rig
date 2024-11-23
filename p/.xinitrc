xinput set-prop 'SYNA8004:00 06CB:CD8B Touchpad' 'libinput Natural Scrolling Enabled' 1 &

feh --bg-scale .config/wallpaper.png &

xset s off
xset -dpms
xset s noblank

dwmblocks &
exec dwm
