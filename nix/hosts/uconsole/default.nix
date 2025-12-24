{ flake, inputs, ... }:
let
  system = "aarch64-linux";

  # Create a perSystem equivalent for accessing packages from different nixpkgs versions
  perSystemOutputs = {
    nixpkgs-25-05 = {
      pkgs = import inputs.nixpkgs-25-05 {
        inherit system;
        config.allowUnfree = true;
      };
    };
  };
in
{
  class = "nixos";

  # Use the OOM fork of nixos-raspberrypi for uConsole hardware support
  value = inputs.oom-hardware-nixos-raspberrypi.lib.nixosSystemFull {
    specialArgs = {
      inherit inputs;
      nixos-raspberrypi = inputs.oom-hardware-nixos-raspberrypi;
      perSystem = perSystemOutputs;
    };
    modules = [
      {
        nixpkgs.hostPlatform = system;
      }
      # Import sd-image and usb-gadget-ethernet from the OOM fork
      inputs.oom-hardware-nixos-raspberrypi.nixosModules.sd-image
      inputs.oom-hardware-nixos-raspberrypi.nixosModules.usb-gadget-ethernet
      ./configuration.nix
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
