{ inputs, osConfig, ... }:
{
  imports = [ inputs.moltbot.homeManagerModules.moltbot ];

  # Signal to the system that moltbot overlay should be applied
  # This will be picked up by the NixOS configuration
  _module.args.needsMoltbotOverlay = true;

  sops.secrets = {
    "moltbot/telegram" = { };
    "moltbot/anthropic" = { };
  };
  programs.moltbot = {
    instances.default = {
      enable = true;
      providers.telegram = {
        enable = true;
        botTokenFile = "/run/secrets/moltbot/telegram";
        allowFrom = [ 8380379284 ]; # your Telegram user ID
      };
      providers.anthropic = {
        apiKeyFile = "/run/secrets/moltbot/anthropic";
      };

      # Explicitly set empty plugins list to override defaults
      plugins = [ ];

      # Built-ins (tools + skills) shipped via nix-steipete-tools.
      # plugins = [
      #   { source = "github:moltbot/nix-steipete-tools?dir=tools/summarize"; }
      # ];
    };
  };
}
