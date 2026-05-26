#!/usr/bin/env bash
set -euo pipefail

# Source MCP environment variables
source ${XDG_RUNTIME_DIR}/mcp.env

# Build connection string from environment variables
DB_USER="${STEAMPIPE_USERNAME:-steampipe}"
DB_PASS="${STEAMPIPE_PASSWORD:-steampipe}"
DB_NAME="${STEAMPIPE_DATABASE:-steampipe}"
DB_TYPE="${STEAMPIPE_TYPE:-postgresql}"
LOCAL_PORT="${LOCAL_PORT:-5432}"

CONNECTION_STRING="${DB_TYPE}://${DB_USER}:${DB_PASS}@localhost:${LOCAL_PORT}/${DB_NAME}"

# Run the MCP server
exec npx -y @turbot/steampipe-mcp "$CONNECTION_STRING"
