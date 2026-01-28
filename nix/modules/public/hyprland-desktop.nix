# nix/modules/public/hyprland-desktop.nix
{ flake, inputs, ... }:
{ config, pkgs, lib, ... }:
{
  imports = [
    ../nixos/hyprland.nix
  ];
}