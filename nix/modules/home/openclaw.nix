{ inputs, config, ... }:
{
  imports = [ inputs.openclaw.homeManagerModules.openclaw ];

  sops.secrets = {
    "openclaw/telegram" = { };
    "openclaw/env" = {
      path = "${config.home.homeDirectory}/.openclaw/.env";
    };
  };
  programs.openclaw = {
    instances.default = {
      enable = true;
      systemd = {
        enable = true;
      };
      config = {
        gateway = {
          mode = "local";
        };
        plugins = {
          entries = {
            telegram = {
              enabled = true;
            };
          };
        };
        channels.telegram = {
          dmPolicy = "pairing";
          tokenFile = config.sops.secrets."openclaw/telegram".path;
          allowFrom = [ 8380379284 ];
          groupPolicy = "allowlist";
          streamMode = "partial";
        };
      };
    };
  };
}
