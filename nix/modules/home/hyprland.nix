{
  pkgs,
  inputs,
  osConfig,
  config,
  ...
}:
{

  programs.hyprpanel.enable = true;

  wayland.windowManager.hyprland.enable = true;

  wayland.windowManager.hyprland = {
    systemd.enable = false;
    settings = {
      decoration = {};
      "$mod" = "SUPER";

      bind = [
        # Execute Rofi with only the SUPER key
        "$mod, Super_L, exec, pkill rofi || rofi -show drun"

        "$mod, K, exec, ghostty"
      ];
      input = {
        kb_layout = "gb";
      };

      # Startup Apps
      exec-once = [
        "hyprpanel"
      ];

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];
    };
  };
}
