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
    # niri system layer (portal, greeter session, polkit, keyring) — replaces
    # the Hyprland NixOS module that used to provide these.
    inputs.crann.modules.nixos.niri
    # noctalia binary cache substituter (noctalia itself is a home program).
    inputs.crann.modules.nixos.noctalia

    inputs.crann.modules.nixos.stylix
    ./peripherals.nix
    ./fonts.nix
    ./gdm.nix
    ./printing.nix
  ];

  crann.niri = {
    enable = true;
    extraSettings = {
      spawn-at-startup = [
        { command = [ "noctalia" ]; }
      ];
    };
  };

  crann.stylix = {
    enable = true;
    extraSettings = {
      targets = {
        regreet.enable = false;
      };
    };
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
