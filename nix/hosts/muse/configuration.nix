# nix build github:jDmacD/blueprint#nixosConfigurations.muse.config.system.build.sdImage
# or
# nix build .#nixosConfigurations.muse.config.system.build.sdImage
# to build the image
# Once deployed it can be updated with
# nixos-rebuild switch --flake .#muse --target-host muse.lan --build-host localhost --use-remote-sudo
# or
# nixos-rebuild switch --flake github:jDmacD/blueprint#muse --target-host muse.lan --build-host localhost --use-remote-sudo
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    # Because we're pulling this into default.nix,
    # we need to use relative paths otherwise it causes a recursion error.
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/host-shared.nix
    ../../modules/nixos/k3s-server.nix
  ];

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
  ];

  networking = {
    hostName = "muse";
    useDHCP = true;
    wireless.enable = true;
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
