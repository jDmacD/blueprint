{ flake, inputs, ... }:
let
  mkRpiHost = import inputs.self.lib.rpi-host {
    inherit inputs flake;
  };
in
mkRpiHost {
  board = "4";
  rpiModules = [
    "sd-image"
    "usb-gadget-ethernet"
  ];
  extraModules = [
    inputs.home-manager.nixosModules.home-manager
    ./configuration.nix
  ];
}
