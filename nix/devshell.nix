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

      curl --insecure -X POST https://example.lan:47990/api/pin -u username:mypassword -H "Content-Type: application/json" -d "{\"pin\":\"PINNUMBERHERE\",\"name\":\"MyClientName\"}"
    '';
  };

  sunshine-pin = pkgs.writeShellApplication {
    name = "sunshine-pin";
    runtimeInputs = [
    ];
    text = ''
      curl \
        --insecure \
        -X POST https://picard.lan:47990/api/pin \
        -u sunshine:sunshine \
        -H "Content-Type: application/json" -d "{\"pin\":\"1535\",\"name\":\"cast\"}"
    '';
  };

in
pkgs.mkShell {
  # Add build dependencies
  packages = [
    create-edid
    sunshine-pin
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
