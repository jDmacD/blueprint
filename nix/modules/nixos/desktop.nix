# nix/modules/nixos/desktop.nix
{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  imports = [
    flake.nixosModules.greetd
    ./stylix.nix
    ./hyprland.nix
    ./peripherals.nix
    ./fonts.nix
    ./noctalia.nix
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
