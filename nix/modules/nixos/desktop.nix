# nix/modules/nixos/desktop.nix
{ flake, inputs, ... }:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # flake.nixosModules.greetd
    ./hyprland.nix
    ./stylix.nix
    # niri system layer (portal, greeter session, polkit, keyring) — replaces
    # the Hyprland NixOS module that used to provide these.
    inputs.crann.modules.nixos.niri
    # noctalia binary cache substituter (noctalia itself is a home program).
    inputs.crann.modules.nixos.noctalia
    ./peripherals.nix
    ./fonts.nix
    # ./noctalia.nix
    ./gdm.nix
    ./printing.nix
  ];

  crann.niri.extraSettings = {
    spawn-at-startup = [
      { command = [ "noctalia" ]; }
    ];
  };

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
  };
}
