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

## 6. Work Tools

1. Login to web tools.
2. Install tools:
   ```bash
   paru -S --noconfirm php nodejs npm docker docker-compose
   sudo usermod -aG docker "$(whoami)"
   ```
3. Enable php iconv for phpactor language server in Zed:
   ```bash
    if grep -Eq '^[;[:space:]]_extension[[:space:]]_=[[:space:]]_iconv([.]so)?[[:space:]]_$' /etc/php/php.ini; then
        sudo sed -Ei 's|^[;[:space:]]*extension[[:space:]]*=[[:space:]]*iconv([.]so)?[[:space:]]*$|extension=iconv|' /etc/php/php.ini
    elif ! grep -Eq '^[[:space:]]_extension[[:space:]]_=[[:space:]]_iconv([[:space:]]_)$' /etc/php/php.ini; then
    echo 'extension=iconv' | sudo tee -a /etc/php/php.ini > /dev/null
    fi
   ```
