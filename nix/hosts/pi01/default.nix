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
    inputs.home-manager-25-05.nixosModules.home-manager
    ./configuration.nix
  ];
}
