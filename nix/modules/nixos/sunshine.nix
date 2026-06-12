{ pkgs, ... }:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl --instance 0";
  sunshine-do = pkgs.writeShellScriptBin "do" ''
    ${pkgs.hyprland}/bin/hyprctl output create headless SUNSHINE-1
    ${pkgs.hyprland}/bin/hyprctl keyword monitor SUNSHINE-1,''${1}x''${2}@''${3},auto,1
    ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-1,disable
  '';
  sunshine-undo = pkgs.writeShellScriptBin "undo" ''
    ${pkgs.hyprland}/bin/hyprctl reload
    ${pkgs.hyprland}/bin/hyprctl output remove SUNSHINE-1
  '';
  sunshine-dune = pkgs.writeShellScriptBin "dune" ''
    setsid steam steam://rungameid/1689500
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    # capSysAdmin = true;
    openFirewall = true;
    settings = {
      capture = "wlr";
    };
    # https://gist.github.com/Dregu/4c0dbb2582835e5d95e06c4bf7624e3b`
    applications = {
      apps = [
        {
          name = "Steam";
          prep-cmd = [
            # {
            #   do = "${hyprctl} output create headless SUNSHINE-1";
            #   undo = "${hyprctl} output remove SUNSHINE-1";
            # }
            {
              do = ''${pkgs.bash}/bin/bash -c "${hyprctl} keyword monitor SUNSHINE-1,''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS},auto,1"'';
              undo = "${hyprctl} keyword monitor SUNSHINE-1,disable";
            }
            # {
            #   do = "${hyprctl} keyword monitor DP-1,disable";
            #   undo = "${hyprctl} reload";
            # }
          ];
          detached = [ "setsid steam steam://open/bigpicture" ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
        {
          name = "Virtual Display";
          prep-cmd = [
            {
              do = ''${sunshine-do}/bin/do "''${SUNSHINE_CLIENT_WIDTH}" "''${SUNSHINE_CLIENT_HEIGHT}" "''${SUNSHINE_CLIENT_FPS}"'';
              undo = "${sunshine-undo}/bin/undo";
            }
          ];
        }
        {
          name = "Dune";
          prep-cmd = [
            {
              do = ''${sunshine-do}/bin/do "''${SUNSHINE_CLIENT_WIDTH}" "''${SUNSHINE_CLIENT_HEIGHT}" "''${SUNSHINE_CLIENT_FPS}"'';
              undo = "${sunshine-undo}/bin/undo";
            }
          ];
          detached = [ "${sunshine-dune}/bin/dune" ];
          auto-detach = "true";
          wait-all = "true";
          exit-timeout = "5";
        }
      ];

    };
  };

}
