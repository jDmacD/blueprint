{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = with inputs.self.nixosModules; [
    rpi-common
    k3s-agent
  ];

  # home-manager = {
  #   extraSpecialArgs = { inherit inputs; };
  #   users.jmacdonald = ./users/jmacdonald/home-configuration.nix;
  # };

  networking.hostName = "pi01";
  system.stateVersion = "25.05"; # Did you read the comment?
}
