{
  pkgs,
  config,
  osConfig,
  ...
}:
let
  screenshot = pkgs.writeShellScriptBin "click" ''
    IMG_DIR=${config.home.homeDirectory}/Pictures/Screenshots
    mkdir -p $IMG_DIR
    ${pkgs.grimblast}/bin/grimblast --notify --freeze copysave area $IMG_DIR/$(date +%Y%m%d%H%M%S).png
  '';
in
{

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    settings = {
      monitor =
        [
          # Fallback for unknown monitors (important for headless/Sunshine)
          ",preferred,auto,1"
        ]
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

      windowrule = [
        # "workspace special:quake, match:title ^quake.*"
      ];

      workspace = [
      ]
      ++ (pkgs.lib.optionals (osConfig.networking.hostName == "lwh-hotapril") [
        "10, monitor:eDP-1"
      ]);

      bind = [
        "$mod, C, exec, uwsm app -- code"
        "$mod, F, fullscreen"
        "$mod, K, exec, uwsm app -- foot"
        "$mod, L, exec, noctalia-shell ipc call lockScreen lock"
        "$mod, X, killactive"
        "$mod, SPACE, exec, noctalia-shell ipc call launcher toggle"
        "$mod, TAB, exec, noctalia-shell ipc call launcher toggle"
        "$mod, ESCAPE, togglespecialworkspace, quake"

        "$mod, right, workspace, m+1"
        "$mod, left, workspace, m-1"

        # Switch workspaces with mainMod + [0-9]
        "$mod, 0, workspace, 10"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        "$mod SHIFT, right, resizeactive, 30 0"
        "$mod SHIFT, left, resizeactive, -30 0"
        "$mod SHIFT, up, resizeactive, 0 -30"
        "$mod SHIFT, down, resizeactive, 0 30"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        "$mod, S, togglespecialworkspace, magic"

        "$mod, Print, exec, flameshot gui"
        ", Print, exec, ${screenshot}/bin/click"
        ", XF86AudioRaiseVolume, exec, noctalia-shell ipc call volume increase"
        ", XF86AudioLowerVolume, exec, noctalia-shell ipc call volume decrease"
        ", XF86MonBrightnessUp, exec, noctalia-shell ipc call brightness increase"
        ", XF86MonBrightnessDown, exec, noctalia-shell ipc call brightness decrease"
      ];
      # Startup Apps
      exec-once = [
        # "noctalia-shell"
        # "systemctl --user enable --now hypridle.service"
        "[workspace special:quake silent] uwsm app -- foot zellij attach -c quake"
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
