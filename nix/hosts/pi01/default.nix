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
          imports =
            (with nixos-raspberrypi.nixosModules; [
              ./configuration.nix
              raspberry-pi-4.base
              sd-image
              usb-gadget-ethernet
            ])
            ++ [
              inputs.sops-nix.nixosModules.sops
            ];
        }
      )
    ];
  };
}
