# Personal Linux Fleet

I value simplicity and minimalism. Even as a computer scientist, I use as little software as possible. I want my operating system to be lightweight, performant, and free from telemetry and spyware. Full configurability and complete control over my system are essential to me. Therefore, I exclusively use [Arch Linux](https://archlinux.org/).

The base install is managed by [`install.sh`](install.sh), and I have a [`just` command](justfile) for each of my device setups. Any and all manual steps are documented below.

## Pre-installation

1. Flash the [Arch Linux ISO](https://www.archlinux.org/download/) to a USB drive.

2. Insert the USB drive into the computer and temporarily boot into it via the BIOS boot menu.

3. Enter the Arch Linux live environment.

4. If using a wireless network, connect to it over WiFi. The install script falls back to `iwctl` if it cannot reach a network, so connect beforehand:

   List available devices:

   ```bash
   iwctl device list
   ```

   Scan for available networks:

   ```bash
   iwctl station <device> scan
   ```

   List available networks:

   ```bash
   iwctl station <device> get-networks
   ```

   Connect to the network:

   ```bash
   iwctl --passphrase <password> station <device> connect <network>
   ```

   Test the connection:

   ```bash
   ping archlinux.org
   ```

## Installation

5. Fetch the install script:

   ```bash
   curl -O https://raw.githubusercontent.com/dan-smith-tech/rig/main/install.sh
   ```

6. Make the script executable:

   ```bash
   chmod +x install.sh
   ```

7. Run the install and follow the prompts:

   ```bash
   ./install.sh
   ```

8. Reboot the device.

## Post-installation

9. Log in and, if using a wireless network, connect to it over WiFi:

   ```bash
   nmcli device wifi connect <network> --ask
   ```

10. Clone this repo:

    ```bash
    git clone https://github.com/dan-smith-tech/rig.git
    ```

11. Run the setup for the relevant device:

    ```bash
    just <device>
    ```

12. Reboot the device.

## Manual Steps

### Plasma

1. Open **System Settings** and configure:

   1. Global Theme Colours, Icons, Login Screen
   1. Keyboard -> Virtual Keyboard -> Plasma Keyboard
   1. Wallpaper (plus Layout set to `Desktop`)
   1. Screen Locking
   1. Power Management
   1. Users
   1. Session

2. Right click on the Panel and select `Panel Configuration` to set up and manage the applets on the bar.

3. Right click on the Panel and select `Add or Manage Widgets...`, then select and remove the KDE Logo, Task Manager, Pager, and replace the Peek with a Margins Separator.

4. Press `Meta + T` to configure the window layout settings.

5. Create shortcuts:

   1. Plasma Workspace: `Meta`

### Brave

1. Install the Proton Pass extension.

1. Sync settings at brave://settings/braveSync/setup.

1. Open brave://settings and configure:

   1. Get started:
      1. On startup
      1. Customise new tab page
   1. Appearance
   1. Content:
      1. Containers
   1. Shields
      1. Forget me
      1. Content filtering
      1. Social media blocking
   1. Privacy and security
      1. Data collection
   1. Leo
   1. Autofill and passwords
   1. Downloads
   1. System:
      1. Show full-screen reminder to press Esc on exit

1. Customise the toolbar icons.

### GitHub

1. Copy public key:
   ```bash
   wl-copy < ~/.ssh/id_ed25519.pub
   ```
1. Open [GitHub Settings -> SSH and GPG keys](https://github.com/settings/keys)
1. Select `New SSH key`, paste the content, and save.
1. Switch this repository to the SSH remote:
   ```bash
   git remote set-url origin git@github.com:dan-smith-tech/rig.git
   ```

### Steam

1. Add the following Gamescope settings to launch settings:

   ```bash
   gamescope -W 3440 -H 1440 -w 3440 -h 1440 -r 144 --hdr-enabled --hdr-debug-force-output --fullscreen --force-grab-cursor -- env DXVK_HDR=1 ENABLE_HDR_WSI=1 %command% --launcher-skip
   ```

### SSH

#### Client

1. Add a host entry to `~/.ssh/config` (using the server's LAN IP - find it on the server with `ip a`):

   ```ssh-config
   Host homelab
       HostName 192.168.x.x
       User dan
       IdentityFile ~/.ssh/id_ed25519
   ```

2. Copy the public key to the clipboard:

   ```bash
   wl-copy < ~/.ssh/id_ed25519.pub
   ```

#### Server

1. Create the SSH directory and allow the client's public key:

   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nvim ~/.ssh/authorized_keys
   ```

   > Test from the client:
   >
   > ```bash
   > ssh homelab
   > ```

### VPN

#### Router

1. **Disable CGN**: A dedicated public IP is required. Disable "Carrier-Grade NAT" or "Large Scale NAT" in the router settings.
2. **Static IP or DynDNS**:
   - If a static public IP is available, use it directly as the client endpoint.
   - Otherwise, set up DynDNS (No-IP) to give the changing public IP a stable hostname:
     - Create a free account at [No-IP](https://www.noip.com).
     - Add a hostname record (e.g., `myhomelab.ddns.net`) and **enable Dynamic DNS**.
     - In the router's DynDNS tab, set service to No-IP and enter the hostname, username, and password.
3. **Port Forwarding**: Assign a static LAN IP to the homelab server, then add a NAT/PAT rule to the router:
   - Internal/External Port: `51820`
   - Protocol: `UDP`
   - Target: Server static LAN IP

#### Keys

1. Generate a keypair on both the server and the client:

   ```bash
   umask 077
   wg genkey > ~/.wg-private.key
   wg pubkey < ~/.wg-private.key > ~/.wg-public.key
   ```

#### Server

1. Create `/etc/wireguard/wg0.conf`:

   ```ini
   [Interface]
   Address = 192.168.2.1/24
   ListenPort = 51820
   PrivateKey = <contents of server ~/.wg-private.key>

   [Peer]
   PublicKey = <contents of client ~/.wg-public.key>
   AllowedIPs = 192.168.2.2/32
   ```

   Add a separate `[Peer]` block for each client, with `AllowedIPs` set to that client's tunnel address.

2. Start the interface, and enable IP forwarding so LAN devices can reply to tunnel traffic:

   ```bash
   sudo wg-quick up wg0
   sudo systemctl enable wg-quick@wg0
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-wireguard.conf
   sudo sysctl -p /etc/sysctl.d/99-wireguard.conf
   ```

3. Persist the NAT rules for the `br0` bridge across reboots:

   ```bash
   cat <<'EOF' | sudo tee /etc/nftables.conf > /dev/null
   table ip nat {
       chain postrouting {
           type nat hook postrouting priority srcnat; policy accept;
           oifname "br0" masquerade
       }
   }
   EOF
   sudo systemctl enable --now nftables
   ```

#### Client

1. Create `/etc/wireguard/wg0.conf`:

   ```ini
   [Interface]
   Address = 192.168.2.2/24
   PrivateKey = <contents of client ~/.wg-private.key>

   [Peer]
   PublicKey = <contents of server ~/.wg-public.key>
   Endpoint = <no-ip-hostname-or-static-public-ip>:51820
   AllowedIPs = 192.168.2.1/32, 192.168.1.0/24
   ```

   The last octet of the client `Address` (`.2`) is its index within the `192.168.2.0/24` subnet — `.2` for the first client, `.3` for the second, and so on.

2. Connect to the tunnel

   ```bash
   sudo wg-quick up wg0
   sudo systemctl enable wg-quick@wg0
   ```

#### Test

1. From a remote client, verify tunnel and LAN access:

   ```bash
   ping 192.168.2.1
   curl http://192.168.1.21:8123
   ```

### Wake-on-LAN

1. Enable in BIOS (Advanced -> APM Configuration -> Power On by PCI-E).
2. Find the MAC address to use:

   ```bash
   ip link show
   ```
