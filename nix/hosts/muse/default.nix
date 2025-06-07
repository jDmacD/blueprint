{ flake, inputs, ... }:
{
  class = "nixos";

  value = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = inputs;
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
            # Hardware configuration
            raspberry-pi-5.base
            raspberry-pi-5.display-vc4
            sd-image
          ];
        }
      )
    ];
  };
}
