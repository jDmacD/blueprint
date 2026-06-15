{
  ...
}:
{
  # Minimal Hyprland session dedicated to Sunshine streaming on picard.
  #
  # The `sunshine` user runs its own headless Hyprland session whose only job is
  # to host the virtual display that Moonshine clients connect to. Unlike the
  # interactive desktop config (./hyprland.nix), this session must NOT enable the
  # physical monitor (DP-1): Sunshine's wlr capture backend ignores `output_name`
  # and simply grabs the first output it resolves. By only ever enabling the
  # virtual output (DP-2, forced on via a fake EDID in modules/nixos/sunshine.nix),
  # Sunshine has exactly one output to capture and always streams the right one.
  #
  # DP-2's mode is re-set per client by the Sunshine `do` prep-cmd to match the
  # client's resolution/refresh; the mode below is just the idle default.

  # The sunshine Hyprland session needs to restart to pick up the new config 
  # — either reboot picard, or log out/in the sunshine session 
  # (loginctl terminate-user sunshine, autologin brings it back).

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    # Keep the hyprlang config format (new default is "lua" from stateVersion 26.05).
    configType = "hyprlang";
    settings = {
      monitor = [
        # Never enable the physical monitor in the streaming session.
        "DP-1, disable"
        # Virtual display Sunshine captures (overridden per-client by the `do` script).
        "DP-2, preferred, auto, 1"
      ];

      "$mod" = "SUPER";

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
      ];

      input = {
        kb_layout = "gb";
      };

      # Lean visuals to keep the encode cheap.
      decoration = {
        blur.enabled = false;
        shadow.enabled = false;
      };
      animations.enabled = false;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Just enough to manage windows when driving the session remotely.
      bind = [
        "$mod, X, killactive"
        "$mod, F, fullscreen"
        # Spawn a GDM greeter on a new VT (GNOME "switch user") so a real user
        # can log in physically even though the sunshine user autologs in.
        # Switches the physical display to the greeter; streaming pauses until
        # you switch back (Ctrl+Alt+F2) or log out of the other session.
        "$mod, U, exec, dbus-send --system --print-reply --dest=org.gnome.DisplayManager /org/gnome/DisplayManager/LocalDisplayFactory org.gnome.DisplayManager.LocalDisplayFactory.CreateTransientDisplay"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
