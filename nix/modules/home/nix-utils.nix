{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    cachix
    deploy-rs
    nixos-rebuild
    nixos-rebuild-ng
    nixos-anywhere
    disko
  ];
}
