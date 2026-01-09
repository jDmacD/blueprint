#!/usr/bin/env bash
set -euo pipefail

export GITLAB_HOST=git.heanet.ie

export GITLAB_PERSONAL_ACCESS_TOKEN=$(yq '.hosts.[env(GITLAB_HOST)].token' ${HOME}/.config/glab-cli/config.yml)
export GITLAB_API_URL=https://${GITLAB_HOST}/api/v4
export GITLAB_READ_ONLY_MODE=true
export USE_PIPELINE=false

# Run the MCP server
exec npx -y @zereight/mcp-gitlab
