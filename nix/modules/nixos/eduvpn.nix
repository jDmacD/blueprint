{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}:

{
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  environment.systemPackages = [
    perSystem.nixpkgs-24-11.eduvpn-client
  ];
}
