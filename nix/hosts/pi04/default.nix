{ flake, inputs, ... }:
let
  mkRpiHost = import ../../lib/rpi-host.nix {
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
