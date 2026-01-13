#!/usr/bin/env bash
set -euo pipefail

# Show help
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat <<'EOF'
Usage: register-domain [DOMAIN] [HOSTNAME] [IP]

Register or update a DNS A record in Cloudflare.

Arguments:
DOMAIN      Domain name (default: jtec.xyz)
HOSTNAME    Hostname to register (default: auto-detect)
IP          IP address to register (default: auto-detect)

Examples:
# Auto-detect hostname and IP, use default domain
register-domain

# Auto-detect hostname and IP, use custom domain
register-domain example.com

# Manually specify everything
register-domain jtec.xyz pi01 192.168.178.50

# Manually specify hostname, auto-detect IP
register-domain jtec.xyz myhost

The script will:
1. Check DNS with dig for fast validation (no API call if already correct)
2. Query Cloudflare API if DNS doesn't match
3. Create new record if it doesn't exist
4. Update existing record if IP has changed
5. Skip update if record is already correct (idempotent)

Requires:
- Cloudflare API credentials via one of:
    * CF_API_KEY environment variable
    * CF_DNS_API_TOKEN environment variable (will be used as CF_API_KEY)
    * ~/.cfcli.yml configuration file (for interactive use)
- Network connectivity for DNS queries and API calls
EOF
    exit 0
fi

# Handle Cloudflare credentials
# cfcli expects CF_API_KEY, but ACME provides CF_DNS_API_TOKEN
# If CF_API_KEY is not set but CF_DNS_API_TOKEN is, use it
if [ -z "${CF_API_KEY:-}" ] && [ -n "${CF_DNS_API_TOKEN:-}" ]; then
    export CF_API_KEY="$CF_DNS_API_TOKEN"
fi
# If neither is set, cfcli will fall back to ~/.cfcli.yml (for interactive use)

# Parse arguments
DOMAIN=${1:-jtec.xyz}
HOSTNAME=${2:-}
IP=${3:-}

# Auto-detect if not provided
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=$(hostname -s)
    [ -z "$HOSTNAME" ] && { echo "Error: Could not detect hostname"; exit 1; }
fi

if [ -z "$IP" ]; then
    # Get the IP of the primary interface (the one used for default route)
    IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    [ -z "$IP" ] && { echo "Error: Could not detect IP address"; exit 1; }
fi

FQDN="$HOSTNAME.$DOMAIN"

echo "Checking DNS record for $FQDN..."

# Quick check with dig first (fast, no API call)
DNS_IP=$(dig +short "$FQDN" A | tail -n1)

if [ "$DNS_IP" = "$IP" ]; then
    echo "✓ Record already up to date: $FQDN → $IP"
    exit 0
fi

# DNS doesn't match or doesn't exist, check Cloudflare authoritatively
EXISTING=$(cfcli find "$FQDN" -f json 2>/dev/null || echo "[]")
CURRENT_IP=$(echo "$EXISTING" | jq -r '.[0].content // empty')

if [ -z "$CURRENT_IP" ]; then
    echo "No existing record found. Creating new record: $FQDN → $IP"
    if cfcli -t A add "$FQDN" "$IP"; then
    echo "✓ Successfully created $FQDN"
    else
    echo "✗ Failed to create $FQDN"
    exit 1
    fi
elif [ "$CURRENT_IP" = "$IP" ]; then
    echo "✓ Cloudflare record correct, waiting for DNS propagation: $FQDN → $IP"
    exit 0
else
    echo "Record exists with different IP: $CURRENT_IP"
    echo "Updating record: $FQDN → $IP"

    if cfcli rm "$FQDN" 2>/dev/null && \
        cfcli -t A add "$FQDN" "$IP"; then
    echo "✓ Successfully updated $FQDN"
    else
    echo "✗ Failed to update $FQDN"
    exit 1
    fi
fi