{
  pkgs,
  ...
}:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "noctalia-shell ipc call lockScreen lock";
      };
      listener = [
        {
          timeout = 900;
          on-timeout = "noctalia-shell ipc call lockScreen lock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
