# Cheatsheet

## 1. If pacman mirrors start to `404`

Delete the mirror sync and refresh the package databases:

```bash
sudo rm -rf /var/lib/pacman/sync/*
sudo pacman -Syy
```
