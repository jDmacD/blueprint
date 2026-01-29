{ config, pkgs, lib, ... }:
let
  cfg = config.services.hyprland-headless;
in
{
  options.services.hyprland-headless = {
    enable = lib.mkEnableOption "headless Hyprland session with UWSM";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to run the headless Hyprland session";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable autologin to TTY1
    services.getty.autologinUser = cfg.user;

    # Configure uwsm with Hyprland compositor
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "${pkgs.hyprland}/bin/start-hyprland";
        };
      };
    };

    # Create systemd user service to start Hyprland via uwsm
    systemd.user.services.hyprland-headless = {
      description = "Headless Hyprland session managed by UWSM";
      wantedBy = [ "default.target" ];
      after = [ "graphical-session-pre.target" ];
      before = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        Slice = "session.slice";
      };

      # Start Hyprland via uwsm
      script = ''
        # Wait a moment for the session to be fully ready
        sleep 2

        # Start Hyprland with uwsm using full path
        exec ${pkgs.uwsm}/bin/uwsm start ${pkgs.hyprland}/bin/Hyprland
      '';

      environment = {
        XDG_RUNTIME_DIR = "/run/user/%U";
        XDG_DATA_DIRS = "/run/current-system/sw/share";
      };
    };

    # Enable the service for the specified user
    system.activationScripts.enableHyprlandHeadless = lib.stringAfter [ "users" ] ''
      ${pkgs.systemd}/bin/systemctl --user --machine=${cfg.user}@ enable hyprland-headless.service || true
    '';
  };
}
