{ pkgs, ... }:
{
  services = {
    intune.enable = true;
    xserver.enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };
}
