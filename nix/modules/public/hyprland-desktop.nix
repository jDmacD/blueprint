# nix/modules/public/hyprland-desktop.nix
{ flake, inputs, ... }:
{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/nixos/hyprland.nix
  ];
}