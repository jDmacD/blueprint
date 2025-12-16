{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    devbox
    jq
    yq-go
  ];

}
