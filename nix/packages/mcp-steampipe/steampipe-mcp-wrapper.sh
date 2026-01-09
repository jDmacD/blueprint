#!/usr/bin/env bash
set -euo pipefail

# Source MCP environment variables
source ${XDG_RUNTIME_DIR}/mcp.env

# Configuration
KUBE_CONTEXT="rke2-b-monitoring"
NAMESPACE="steampipe"
SERVICE="steampipe"
REMOTE_PORT="3306"
LOCAL_PORT="9193"

# Build connection string from environment variables
DB_USER="${STEAMPIPE_USERNAME:-steampipe}"
DB_PASS="${STEAMPIPE_PASSWORD:-}"
DB_NAME="${STEAMPIPE_DATABASE:-steampipe}"
DB_TYPE="${STEAMPIPE_TYPE:-postgresql}"

if [[ -n "$DB_PASS" ]]; then
  CONNECTION_STRING="${DB_TYPE}://${DB_USER}:${DB_PASS}@localhost:${LOCAL_PORT}/${DB_NAME}"
else
  CONNECTION_STRING="${DB_TYPE}://${DB_USER}@localhost:${LOCAL_PORT}/${DB_NAME}"
fi

# Cleanup function
cleanup() {
  if [[ -n "${PORT_FORWARD_PID:-}" ]] && kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
    echo "Cleaning up port-forward (PID: $PORT_FORWARD_PID)..." >&2
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
    wait "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

# Start port-forward in background
echo "Starting kubectl port-forward..." >&2
kubectl --context "$KUBE_CONTEXT" \
  -n "$NAMESPACE" \
  port-forward "svc/$SERVICE" \
  "${LOCAL_PORT}:${REMOTE_PORT}" \
  >/dev/null 2>&1 &

PORT_FORWARD_PID=$!

# Wait for port to be ready
echo "Waiting for port-forward to be ready..." >&2
MAX_ATTEMPTS=30
ATTEMPT=0
while ! nc -z localhost "$LOCAL_PORT" 2>/dev/null; do
  ATTEMPT=$((ATTEMPT + 1))
  if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
    echo "Error: Port-forward failed to become ready after ${MAX_ATTEMPTS} seconds" >&2
    exit 1
  fi
  if ! kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
    echo "Error: Port-forward process died unexpectedly" >&2
    exit 1
  fi
  sleep 1
done

echo "Port-forward ready, starting Steampipe MCP server..." >&2

# Run the MCP server
exec npx -y @turbot/steampipe-mcp "$CONNECTION_STRING"
