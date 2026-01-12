#!/usr/bin/env bash
# k3s-post-rebuild.sh
# Flush ARP caches after rebuilding a k3s node to clear stale L2 announcement mappings
#
# Usage: k3s-post-rebuild.sh [node-name]
#
# This script resolves connectivity issues when Cilium L2 announcement leases
# fail over between nodes during k3s/NixOS rebuilds. Even with OPNsense ARP
# timeout reduced to 60 seconds, this provides immediate recovery.

set -euo pipefail

NODE_NAME="${1:-$(hostname)}"
OPNSENSE_HOST="${OPNSENSE_HOST:-192.168.178.1}"
GATEWAY_IPS=(192.168.178.249 192.168.178.250 192.168.178.251)

echo "🔧 K3s Post-Rebuild ARP Cache Flush"
echo "   Node: $NODE_NAME"
echo ""

# Flush local ARP cache
echo "  → Flushing local ARP cache..."
if sudo ip -s -s neigh flush all >/dev/null 2>&1; then
    echo "    ✓ Local cache cleared"
else
    echo "    ✗ Failed to flush local cache (sudo required)"
    exit 1
fi
echo ""

# Flush OPNsense ARP cache
echo "  → Flushing OPNsense ARP cache ($OPNSENSE_HOST)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "root@$OPNSENSE_HOST" "arp -d -a" 2>/dev/null; then
    echo "    ✓ OPNsense cache cleared"
else
    echo "    ⚠ Could not flush OPNsense ARP cache"
    echo "      Manual fix: ssh root@$OPNSENSE_HOST 'arp -d -a'"
fi
echo ""

# Wait for Cilium L2 announcements to propagate
echo "  → Waiting for Cilium L2 announcements to stabilize..."
sleep 5
echo ""

# Test gateway connectivity
echo "  → Testing gateway connectivity..."
FAILED=0
for gw in "${GATEWAY_IPS[@]}"; do
    if timeout 3 curl -s -I "http://$gw" >/dev/null 2>&1; then
        echo "    ✓ $gw responding"
    else
        echo "    ✗ $gw not responding"
        FAILED=1
    fi
done
echo ""

# Final status
if [ $FAILED -eq 1 ]; then
    echo "⚠ Some gateways not responding"
    echo ""
    echo "Possible causes:"
    echo "  • Cilium still rebalancing L2 announcement leases"
    echo "  • Deco mesh nodes need 1-2 minutes to relearn ARP"
    echo "  • OPNsense ARP cache not cleared (check SSH access)"
    echo ""
    echo "Solutions:"
    echo "  • Wait 60-120 seconds (OPNsense ARP timeout is 60s)"
    echo "  • Manually flush: ssh root@$OPNSENSE_HOST 'arp -d -a'"
    echo "  • Check L2 leases: kubectl get leases -n kube-system | grep cilium-l2announce"
    exit 1
else
    echo "✅ All gateways responding!"
    echo "   Deco mesh clients may take 1-2 minutes to fully recover."
fi
