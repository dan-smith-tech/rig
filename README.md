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

### Zed

#### Context7

1. Open **Settings** -> **AI** -> **MCP Servers** and select the sign-in link for `context7`. Zed opens a browser.

1. Sign in with GitHub and authorise Context7.

1. Back in Zed, `context7` should show as active and its tools available to the agent.

When the token expires, the server shows as offline and its tools stop working. Repeat the steps above to re-authenticate.

#### RTK

1. After a few days of usage check the token savings:

   ```bash
   rtk gain
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

### HTPC

The homelab doubles as the HTPC. Plasma is not started at boot. Home Assistant starts it over SSH when an app is chosen, and Brave opens fullscreen in that app. Choosing `off` stops the session.

#### Home Assistant SSH key

1. In the Home Assistant VS Code add-on, open a terminal and generate a key into the config folder so it survives updates:

   ```bash
   mkdir -p /config/.ssh
   ssh-keygen -t ed25519 -N "" -C homeassistant -f /config/.ssh/id_ed25519
   cat /config/.ssh/id_ed25519.pub
   ```

2. Copy the public key output.

3. On the homelab, add it to `~/.ssh/authorized_keys`, prefixed so the key can only run `htpc-launch`:

   ```bash
   restrict,command="/usr/local/bin/htpc-launch" ssh-ed25519 AAAA... homeassistant
   ```

4. Reserve the homelab's IP address in the router, as the Home Assistant config below uses it.

5. Test from the Home Assistant terminal, using the homelab's LAN address (find it with `ip -4 addr show br0`):

   ```bash
   ssh -i /config/.ssh/id_ed25519 dan@192.168.1.20 youtube
   ssh -i /config/.ssh/id_ed25519 dan@192.168.1.20 off
   ```

Accept the host key on the first connection. The first command should start Plasma and Brave on the TV, and the second should stop them.

#### Home Assistant config

1. Add the shell command to `configuration.yaml`, then check the configuration and restart. This step has no UI equivalent:

   ```yaml
   shell_command:
     htpc_launch: "ssh -i /config/.ssh/id_ed25519 -o UserKnownHostsFile=/config/.ssh/known_hosts -o StrictHostKeyChecking=accept-new dan@192.168.1.20 '{{ app }}'"
   ```

2. Create the dropdown: Settings -> Devices & services -> Helpers -> Create helper -> Dropdown.

   1. Name: `HTPC app`
   1. Options: `off`, `youtube`, `netflix`
   1. Icon: `mdi:television`

   This creates `input_select.htpc_app`.

3. Create the automation: Settings -> Automations & scenes -> Create automation -> Create new automation. Open the three dots menu, choose `Edit in YAML`, and paste:

   ```yaml
   alias: HTPC app changed
   triggers:
     - trigger: state
       entity_id: input_select.htpc_app
   actions:
     - action: shell_command.htpc_launch
       data:
         app: "{{ states('input_select.htpc_app') }}"
   ```

4. Add the `HTPC app` dropdown to a dashboard. In other automations, set it with the `input_select.select_option` action.

#### Plasma

1. Choose `youtube` in the `HTPC app` dropdown, plug in a keyboard, and open **System Settings** to configure:

1. Screen Locking (disable)
1. Power Management (never sleep, never turn off the screen)
1. Display and Monitor (check the TV resolution and scale)

#### KDE Connect

Use the phone as a mouse and keyboard to drive the HTPC. `kdeconnect` is installed and its daemon auto-starts with the Plasma session, so it only needs the session running.

1. Install the [KDE Connect](https://kdeconnect.kde.org/) app on the phone, enable it, and make sure the phone and HTPC share a network.
2. Start the HTPC session (pick any app in the `HTPC app` dropdown) and, for this one-time pairing, plug in a keyboard.
3. From the phone, request pairing with the HTPC and then mouse and keyboard, and accept the prompts on the HTPC itself.

#### YouTube pairing

1. Choose `youtube` in the `HTPC app` dropdown.
2. With a keyboard (or KDE Connect), open Settings in the YouTube TV interface and choose `Link with TV code`.
3. In the YouTube phone app, go to Settings -> Watch on TV -> Enter TV code.
4. The pairing lives in `~/.config/brave-htpc`, so it only needs doing once.

#### Adding an app

1. Add the name to the `case` in `htpc-launch` and a block in `htpc-session`, both inside the justfile.
2. Add the name to the `input_select` options in Home Assistant.
3. Rerun `just homelab`.
