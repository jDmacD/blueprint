#!/usr/bin/env bash
set -euo pipefail

source ${XDG_RUNTIME_DIR}/mcp.env

# Run the MCP server
exec npx -y argocd-mcp@latest stdio
