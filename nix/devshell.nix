{ pkgs, perSystem }:
let
  create-edid = pkgs.writeShellApplication {
    name = "create-edid";
    runtimeInputs = [
      perSystem.self.create-edid
      pkgs.v4l-utils
    ];
    text = ''
      create-edid nix/modules/nixos/virtual-display.bin
      edid-decode  nix/modules/nixos/virtual-display.bin
    '';
  };

in
pkgs.mkShell {
  # Add build dependencies
  packages = [ create-edid ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
