# Post-Install Configuration

Run [`configure.sh`](./configure.sh) first, then follow the steps below to finish setting up the system.

---

## 1. GitHub SSH Key

Add the generated public key to GitHub so you can push without a password:

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Go to **[GitHub Settings → SSH and GPG keys](https://github.com/settings/keys)**
3. Click **New SSH key**, paste the content, and save.

## 2. KDE Plasma (System Settings)

Open **System Settings** and configure:

- Shortcuts
- Display resolution / orientation
- Wallpaper
- Theme
- Panel layout & settings
- _Optional:_ Natural scrolling in mouse/touchpad settings

## 3. Brave Browser

Open `brave://settings` and configure:

- Privacy and security preferences
- Disable persistent cookies
- Disable telemetry
- Install content filters / blockers
- Apply **Catppuccin Mocha** theme

## 4. Zed Editor

Launch Zed and configure:

- **Catppuccin Mocha** theme
- **Catppuccin Mocha** icons
- Enable spell checker
- Set up inline and agent Copilot

## 5. Steam (PC only)

_Optional — skip if on laptop._

Sign into Steam and install your games.

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
