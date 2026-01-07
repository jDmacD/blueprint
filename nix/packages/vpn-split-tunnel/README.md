# VPN Split Tunnel

NetworkManager dispatcher script that automatically enables split tunneling for EduVPN connections.

## Purpose

When connected to a VPN, by default all network traffic routes through the VPN tunnel. This prevents access to local network resources (like `.lan` domains, local printers, NAS, etc.) while the VPN is active.

This package solves that problem by automatically configuring VPN connections to use split tunneling, allowing simultaneous access to:
- Work resources through the VPN
- Local network resources through the local interface

## How It Works

1. NetworkManager triggers the dispatcher script when a VPN connection is established
2. The script detects if it's an EduVPN connection (by matching `*eduvpn*` in the connection name)
3. If matched, it automatically:
   - Sets `ipv4.never-default = true` and `ipv6.never-default = true` (prevents VPN from becoming default route)
   - Sets `ipv4.ignore-auto-routes = true` and `ipv6.ignore-auto-routes = true` (ignores routes pushed by VPN server)
   - Sets `ipv4.dns-priority = 50` and `ipv6.dns-priority = 50` (deprioritizes VPN DNS, allowing local DNS to be used)
   - Deletes any conflicting routes for 192.168.0.0/16 and 10.0.0.0/8 networks
4. These settings prevent the VPN from capturing local network traffic and DNS queries
5. Only work-specific networks route through the VPN; local traffic stays local

**Note:** DNS priority settings require a VPN disconnect/reconnect to take effect. After the first connection, disconnect and reconnect the VPN for split DNS to work properly.

## Usage

This package is used by the `vpn-split-tunnel` NixOS module:

```nix
# In your host configuration.nix
networking.vpnSplitTunnel.enable = true;
```

The dispatcher script is automatically installed to `/etc/NetworkManager/dispatcher.d/` and runs whenever network connections change state.

## Implementation

- **Script:** `vpn-split-tunnel.sh` - Bash script that implements the dispatcher logic
- **Package:** `default.nix` - Nix derivation that builds and wraps the script with required dependencies
- **Dependencies:** NetworkManager (for `nmcli` command)

## Logs

The script logs its actions to the system journal with the `vpn-split-tunnel` tag:

```bash
# View split tunnel logs
journalctl -t vpn-split-tunnel

# Follow logs in real-time
journalctl -t vpn-split-tunnel -f
```

## Customization

To match different VPN connection names, modify the case pattern in `vpn-split-tunnel.sh`:

```bash
case "$(echo "$CONNECTION_ID" | tr '[:upper:]' '[:lower:]')" in
  *eduvpn*|*yourvpn*)  # Add more patterns here
    # ... configuration logic
    ;;
esac
```

## Related

- NixOS Module: `nix/modules/nixos/vpn-split-tunnel.nix`
- EduVPN Module: `nix/modules/nixos/eduvpn.nix`
