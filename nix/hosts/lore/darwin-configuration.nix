{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
  ]
  ++ (with inputs.self.nixosModules; [
    host-shared
    homebrew
    stylix
    fonts
    builder-arm
    builder-x86
  ]);

  users.users.jmacdonald.home = "/Users/jmacdonald";

  environment.systemPackages = [
    pkgs.nixos-rebuild-ng
  ];

  networking = {
    hostName = "lore";
    localHostName = "lore";
    domain = "lan";
  };

  nix = {
    linux-builder.enable = true;
    settings.trusted-users = [ "jmacdonald" ];
  };

  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets."armbuilder_ed25519" = {
    owner = "root";
    mode = "0600";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
