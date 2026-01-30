{ ... }:
{
  # https://www.reddit.com/r/NixOS/comments/1qo9alr/need_help_with_gdmhyprlanduwsm_problem/

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
    settings = {
      daemon = {
        AutomaticLoginEnable = true;
        AutomaticLogin = "jmacdonald";
      };
    };
  };

  # FIXME: https://github.com/NixOS/nixpkgs/issues/484328
  services.displayManager.defaultSession = "hyprland-uwsm";

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/start-hyprland";
      };
    };
  };
}
