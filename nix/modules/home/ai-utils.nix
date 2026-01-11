{
  pkgs,
  lib,
  config,
  osConfig,
  perSystem,
  ...
}:
let
  cfg = config.programs.claude-code;
  presets = {
    home = {
      mcpServers = { };
    };
    work = {
      mcpServers = {
        steampipe = {
          type = "stdio";
          command = "${perSystem.self.mcp-steampipe}/bin/steampipe-mcp-wrapper";
        };
        argocd = {
          type = "stdio";
          command = "${perSystem.self.mcp-argocd}/bin/argocd-mcp-wrapper";
        };
        grafana = {
          type = "stdio";
          command = "${perSystem.self.mcp-grafana}/bin/grafana-mcp-wrapper";
        };
        gitlab = {
          type = "stdio";
          command = "${perSystem.self.mcp-gitlab}/bin/gitlab-mcp-wrapper";
        };
      };
    };
  };
  presetConfig = presets.${cfg.preset};
in
{
  options.programs.claude-code = {
    preset = lib.mkOption {
      type = lib.types.enum [
        "work"
        "home"
      ];
      default = "home";
      description = "Which domain preset to use for himmelblau configuration";
    };
  };

  config = {
    sops = {
      secrets.mcp_env = {
        path = "%r/mcp.env";
      };
    };
    programs.claude-code = {
      enable = true;
      mcpServers = presetConfig.mcpServers;
      memory.text = ''
        - This is a Linux NixOS Machine
        - Its hostname is ${osConfig.networking.hostName}
        - The local network domain name is .lan
        - The local subnet is 192.168.178.0/24
        - The nix-shell can be used use to access tools for instance
            - `nix-shell --packages ethtool dnsutils --quiet --run "dig +short picard.lan"`
            - `ssh lwh-hotapril.lan 'nix-shell --packages facter --quiet --run "facter -j"'`
        - search for tools and applications with `nh search <application name>`
      '';
    };
  };
}
