{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    tpi
    zstd
  ];

}