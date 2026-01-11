#!/usr/bin/env bash

# Network diagnostics and iperf tests using SSH + nix-shell
# No Ansible/Python dependencies required on target hosts

HOSTS=(
  "pi01.lan"
  "pi04.lan"
  "pi05.lan"
  "tpi04.lan"
  "picard.lan"
  "surface.lan"
)

IPERF_TARGET="lwh-hotapril.lan"

echo "========================================"
echo "Network Diagnostics Collection"
echo "========================================"
echo

for host in "${HOSTS[@]}"; do
  echo "=== $host ==="
  echo

  echo "--- Interface Information ---"
  ssh "$host" 'ip addr show' 2>/dev/null || echo "Failed to connect to $host"
  echo

  echo "--- Primary Interface Detection ---"
  interface=$(ssh "$host" "ip link show | grep -E '^[0-9]+: (eth|en|end)' | head -1 | cut -d: -f2 | tr -d ' '" 2>/dev/null)
  echo "Primary interface: $interface"
  echo

  if [ -n "$interface" ]; then
    echo "--- Ethtool Info ---"
    ssh "$host" "nix-shell --quiet -p ethtool --run 'ethtool $interface'" 2>/dev/null || echo "ethtool failed"
    echo

    echo "--- Offload Settings ---"
    ssh "$host" "nix-shell --quiet -p ethtool --run \"ethtool -k $interface | grep -E 'segmentation|checksum|scatter'\"" 2>/dev/null || echo "ethtool -k failed"
    echo

    echo "--- TC Qdisc ---"
    ssh "$host" "tc qdisc show dev $interface" 2>/dev/null || echo "tc failed"
    echo

    echo "--- Interface Stats ---"
    ssh "$host" "ip -s link show $interface" 2>/dev/null || echo "ip stats failed"
    echo
  fi

  echo "========================================"
  echo
done

echo
echo "========================================"
echo "iperf3 Performance Tests -> $IPERF_TARGET"
echo "========================================"
echo

for host in "${HOSTS[@]}"; do
  if [ "$host" = "$IPERF_TARGET" ]; then
    echo "Skipping $host (target host)"
    continue
  fi

  echo "=== Test: $host -> $IPERF_TARGET ==="
  echo

  ssh "$host" "nix-shell --quiet -p iperf3 --run 'iperf3 -c $IPERF_TARGET'" 2>/dev/null || echo "iperf3 test failed for $host"

  echo
  echo "========================================"
  echo

  # Small delay between tests
  sleep 2
done

echo "All tests complete!"
