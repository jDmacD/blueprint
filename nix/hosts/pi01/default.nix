{ flake, inputs, ... }:
let
  system = "aarch64-linux";
  # Create a perSystem equivalent for the custom nixosSystemFull
  perSystemOutputs = {
    nixpkgs-24-11 = {
      pkgs = import inputs.nixpkgs-24-11 {
        inherit system;
        config.allowUnfree = true;
      };
    };
  };
in
{
  class = "nixos";

  value = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = {
      inherit (inputs) nixos-raspberrypi;
      perSystem = perSystemOutputs;
    };
    modules = [
      (
        {
          config,
          pkgs,
          lib,
          nixos-raspberrypi,
          perSystem,
          ...
        }:
        {
          imports =
            (with nixos-raspberrypi.nixosModules; [
              raspberry-pi-4.base
              sd-image
              usb-gadget-ethernet
            ])
            ++ [
              ./configuration.nix
              inputs.sops-nix.nixosModules.sops
            ];
        }
      )
    ];
  };
}
