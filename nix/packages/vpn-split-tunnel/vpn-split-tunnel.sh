#!/bin/sh
# NetworkManager dispatcher script for VPN split tunneling
# This script runs when network connections change state

INTERFACE="$1"
ACTION="$2"
CONNECTION_ID="$CONNECTION_ID"
CONNECTION_UUID="$CONNECTION_UUID"

# Only act on VPN connections going up
if [ "$ACTION" != "vpn-up" ]; then
  exit 0
fi

# Check if this is an EduVPN connection (case-insensitive)
case "$(echo "$CONNECTION_ID" | tr '[:upper:]' '[:lower:]')" in
  *eduvpn*)
    logger -t vpn-split-tunnel "Configuring split tunneling for VPN: $CONNECTION_ID (UUID: $CONNECTION_UUID)"

    # Use UUID to avoid issues with duplicate connection names
    TARGET="${CONNECTION_UUID:-$CONNECTION_ID}"

    # Configure split tunneling (don't make VPN the default route)
    nmcli connection modify "$TARGET" ipv4.never-default true 2>/dev/null || true
    nmcli connection modify "$TARGET" ipv6.never-default true 2>/dev/null || true

    # Ignore routes pushed by the VPN server to prevent conflicts with local network
    nmcli connection modify "$TARGET" ipv4.ignore-auto-routes true 2>/dev/null || true
    nmcli connection modify "$TARGET" ipv6.ignore-auto-routes true 2>/dev/null || true

    # Configure split DNS: VPN DNS only for VPN-specific domains, not global
    # DNS priority > 0 means this DNS is only used for the connection's search domains
    nmcli connection modify "$TARGET" ipv4.dns-priority 50 2>/dev/null || true
    nmcli connection modify "$TARGET" ipv6.dns-priority 50 2>/dev/null || true

    # Delete any VPN routes that conflict with local network (192.168.0.0/16)
    # This removes routes pushed by the VPN server for local networks
    ip route show | grep "via.*dev $INTERFACE" | grep "192.168\." | while read route; do
      ip route del $route 2>/dev/null && logger -t vpn-split-tunnel "Deleted conflicting route: $route" || true
    done

    # Delete any VPN routes that conflict with 10.0.0.0/8
    ip route show | grep "via.*dev $INTERFACE" | grep "^10\." | while read route; do
      ip route del $route 2>/dev/null && logger -t vpn-split-tunnel "Deleted conflicting route: $route" || true
    done

    logger -t vpn-split-tunnel "Split tunneling configured for $CONNECTION_ID"
    ;;
esac
