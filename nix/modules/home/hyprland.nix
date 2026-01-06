{
  pkgs,
  inputs,
  osConfig,
  ...
}:
{

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    settings = {
      monitor =
        [ ]
        ++ (pkgs.lib.optionals (osConfig.networking.hostName == "lwh-hotapril") [
          "desc:AU Optronics 0x562D,1920x1080@60.03, 0x0, 1"
          "desc:LG Electronics 38GN950 103NTHMGY473, 3840x1600@59.99, -960x1080, 1"
        ])
        ++ (pkgs.lib.optionals (osConfig.networking.hostName == "surface") [
          "eDP-1, preferred,auto,2"
        ])
        ++ (pkgs.lib.optionals (osConfig.networking.hostName == "picard") [
          "desc:LG Electronics 38GN950 103NTHMGY473,3840x1600@144.00,-0x0,1"
        ]);
      "$mod" = "SUPER";

      bind = [
        "$mod, C, exec, code"
        "$mod, F, fullscreen"
        "$mod, K, exec, ghostty"
        "$mod, R, exec, rofi -show combi -modes combi -combi-modes \"window,drun,ssh\""
        "$mod, X, killactive"

        # Switch workspaces with mainMod + [0-9]
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        "$mod SHIFT, right, resizeactive, 30 0"
        "$mod SHIFT, left, resizeactive, -30 0"
        "$mod SHIFT, up, resizeactive, 0 -30"
        "$mod SHIFT, down, resizeactive, 0 30"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        # Example special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
      ];
      # Startup Apps
      exec-once = [
        "hyprpanel"
      ];
      input = {
        kb_layout = "gb";
      };
      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];
    };
  };
}
