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
    # audio (pipewire) / bluetooth / power (upower) / gvfs
    inputs.crann.modules.nixos.desktop
    inputs.crann.modules.nixos.gdm
    ./peripherals.nix
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

  crann.desktop.enable = true;

  crann.gdm.enable = true;
}
