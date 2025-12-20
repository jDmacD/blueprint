{ flake, inputs, ... }:
let
  mkRpiHost = import inputs.self.lib.rpi-host {
    inherit inputs flake;
  };
in
mkRpiHost {
  board = "5";
  rpiModules = [
    "sd-image"
    "usb-gadget-ethernet"
  ];
  extraModules = [
    inputs.disko.nixosModules.disko
    ./configuration.nix
  ];
}
