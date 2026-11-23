{ inputs, ... }:
{ config, ... }:
# jtec-mcp (github.com/jDmacD/jtec-mcp): workflow-level MCP tools for the
# cluster and home services, registered with Claude Code as `jtec`.
# API keys come from BWS project `jtec` via secretspec; the server itself only
# reads the BWS token (Claude's `bws.claude` machine-account token).
{
  imports = [ inputs.jtec-mcp.homeManagerModules.default ];

  services.jtec-mcp = {
    enable = true;
    settings.services.slskd = {
      # LAN-only route on the internal gateway.
      url = "https://slskd.local.jtec.xyz";
      key_field = "SLSKD_API_KEY";
    };
    # BWS project `jtec`, the one the cluster's external-secrets store reads.
    secretspec.provider = "bws://f2fc98e1-f97e-4cd2-bedf-b24c00954124";
    secretFiles.BWS_ACCESS_TOKEN = config.sops.secrets."bws/claude".path;
  };

  sops.secrets."bws/claude" = { };

  # jDmacD's policy for Claude (the module adds its own generic note too).
  programs.claude-code.context = ''

    ## Using and extending jtec-mcp

    jtec-mcp (`mcp__jtec__*` tools; repo `~/Code/jtec-mcp`,
    github.com/jDmacD/jtec-mcp) is jDmacD's MCP server for cluster and home
    services. Use it before calling a service's API by hand. When a task needs
    a service API by hand (curl, `kubectl exec`, port-forwards, ad-hoc scripts)
    for a step likely to recur, extend jtec-mcp proactively: finish the user's
    task first, then open a branch + PR in jtec-mcp following its CLAUDE.md
    (prefer a maintained Python library, then the service's OpenAPI/Swagger
    spec, then hand-written httpx). jDmacD wants this without being asked; say
    in one line that you opened it.
  '';
}
