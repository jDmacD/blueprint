{ flake, inputs, ... }:
{
  class = "nixos";

  value = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = {
      inherit (inputs) nixos-raspberrypi;
    };
    modules = [
      (
        {
          config,
          pkgs,
          lib,
          nixos-raspberrypi,
          ...
        }:
        {
          imports = with nixos-raspberrypi.nixosModules; [
            ./configuration.nix
            raspberry-pi-5.base
            raspberry-pi-5.display-vc4
            sd-image
          ];
        }
      )
    ];
  };
}
