# Cheatsheet

## 1. If pacman mirrors start to `404`

Delete the mirror sync and refresh the package databases:

```bash
sudo rm -rf /var/lib/pacman/sync/*
sudo pacman -Syy
```

## 2. Run Steam game with Gamescope

```
gamescope -W 3440 -H 1440 -w 3440 -h 1440 -r 144 --hdr-enabled --fullscreen --force-grab-cursor -- %command% --launcher-skip
```
