# nix/modules/nixos/desktop-headless.nix
{ flake, ... }:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Import desktop components except GDM (for headless setups)
  imports = [
    ./stylix.nix
    ./hyprland.nix
    ./peripherals.nix
    ./fonts.nix
    ./noctalia.nix
    # NOT importing gdm.nix - headless doesn't need a display manager
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs.bluez;
    settings.General.Experimental = true;
  };

  services = {
    upower.enable = true;
    blueman.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    kmscon.enable = false;
  };
}
