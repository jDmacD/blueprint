# nix/modules/nixos/desktop.nix
{ flake, inputs, ... }:
{ config, pkgs, lib, ... }:
{
  imports = [
    ./stylix.nix
    ./hyprland.nix
    ./peripherals.nix
    ./fonts.nix
    ./noctalia.nix
    flake.nixosModules.greetd
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