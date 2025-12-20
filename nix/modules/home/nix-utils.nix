{ pkgs, config, ... }:
{

  home.packages = with pkgs; [
    cachix
    deploy-rs
    nixos-rebuild-ng
    nixos-anywhere
    # disko
  ];

  programs.nh = {
    enable = true;
    darwinFlake = "${config.home.homeDirectory}/blueprint";
    flake = "${config.home.homeDirectory}/blueprint";
  };
}
