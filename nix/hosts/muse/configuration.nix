# nix build github:jDmacD/blueprint#nixosConfigurations.muse.config.system.build.sdImage
# OR 
# nix build .#nixosConfigurations.muse.config.system.build.sdImage
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
