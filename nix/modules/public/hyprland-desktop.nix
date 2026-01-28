{ flake, inputs, ... }:
{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/desktop/hyprland.nix
  ];
}