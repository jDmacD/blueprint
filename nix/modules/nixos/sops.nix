{ pkgs, inputs, ... }:
let
  importSops =
    if pkgs.system == "aarch64-darwin" then
      [ inputs.sops-nix.darwinModules.sops ]
    else
      [ inputs.sops-nix.nixosModules.sops ];
in
{
  imports = importSops;

  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
