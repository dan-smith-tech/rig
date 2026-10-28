# Post-Install Configuration

Run `configure-<device>.sh` first, then follow the steps below to finish setting up the system.

## 1. Plasma

Open **System Settings** and configure:

1. Global Theme colours, Icons, Login Screen
2. Wallpaper
3. Screen Locking
4. Power Management
5. Users
6. Session

Right click on the panel and select **Panel Configuration** to setup and bin applets to the bar.

Press `Meta + T` to configure the window layout settings.

## 2. Brave

Install Proton Pass extension.

Sync settings with brave://settings/braveSync/setup.

Open `brave://settings` and configure:

1. Get started:
   1. On startup
   1. Customise new tab page
2. Appearance
3. Content:
   1. Containers
4. Shields
   1. Forget me
   2. Content filtering
   3. Social media blocking
5. Privacy and security
   1. Data collection
6. Leo
7. Autofill and passwords
8. Downloads
9. System:
   1. Show full-screen reminder to press Esc on exit

Enable and disable icons in the toolbar.

## 3. GitHub

Add the generated public key to GitHub so you can push without a password:

1. Copy public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Go to **[GitHub Settings → SSH and GPG keys](https://github.com/settings/keys)**
3. Select **New SSH key**, paste the content, and save.

(Remember repositories need to have SSH origins, not HTTPS)

## 4. Steam

Add the following Gamescope settings to launch settings:

```bash
gamescope -W 3440 -H 1440 -w 3440 -h 1440 -r 144 --hdr-enabled --hdr-debug-force-output --fullscreen --force-grab-cursor -- env DXVK_HDR=1 ENABLE_HDR_WSI=1 %command% --launcher-skip
```
