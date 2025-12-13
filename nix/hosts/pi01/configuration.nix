{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos/host-shared.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/rpi-common.nix
    ../../modules/nixos/k3s-agent.nix
  ]
  ++ (with inputs.self.nixosModules; [
    # rpi4-hardware-configuration
    # host-shared
    # ssh
    # users
    # rpi-common
  ]);

  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets."k3s/token" = {
    owner = "root";
  };
  networking.hostName = "pi01";
  system.stateVersion = "24.05"; # Did you read the comment?
}
