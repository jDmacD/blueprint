# Shared helper for creating Raspberry Pi host configurations with nixos-raspberrypi
# This provides a cleaner alternative to duplicating the default.nix pattern across multiple RPi hosts
{
  inputs,
  flake,
  system ? "aarch64-linux",
}:
{
  # Board variant: "4" for RPi 4B/CM4, "5" for RPi 5
  board,
  # Additional nixos-raspberrypi modules to import (e.g., sd-image, usb-gadget-ethernet)
  rpiModules ? [ ],
  # Additional NixOS modules to import
  extraModules ? [ ],
}:
let
  # Create a perSystem equivalent for accessing packages from different nixpkgs versions
  perSystemOutputs = {
    nixpkgs-25-05 = {
      pkgs = import inputs.nixpkgs-25-05 {
        inherit system;
        config.allowUnfree = true;
      };
    };
  };

  # Select the appropriate base module based on board version
  baseModule =
    if board == "4" then
      inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    else if board == "5" then
      inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    else
      throw "Unsupported board version: ${board}. Use '4' or '5'";
in
{
  class = "nixos";

  value = inputs.nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = {
      inherit inputs;
      inherit (inputs) nixos-raspberrypi;
      perSystem = perSystemOutputs;
    };
    modules = [
      baseModule
      {
        nixpkgs.hostPlatform = system;
      }
    ]
    ++ (map (mod: inputs.nixos-raspberrypi.nixosModules.${mod}) rpiModules)
    ++ extraModules
    ++ [
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
