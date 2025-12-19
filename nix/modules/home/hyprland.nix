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
      decoration = { };
      "$mod" = "SUPER";

      bind = [
        "$mod, K, exec, ghostty"
      ];
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
