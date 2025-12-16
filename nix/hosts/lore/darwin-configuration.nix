{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
    inputs.self.darwinModules.stylix
  ]
  ++ (with inputs.self.nixosModules; [
    host-shared
    homebrew
    fonts
    builder-arm
    builder-x86
  ]);

  users.users.jmacdonald.home = "/Users/jmacdonald";

  environment.systemPackages = [ ];

  networking = {
    hostName = "lore";
    localHostName = "lore";
    domain = "lan";
  };

  nix = {
    linux-builder.enable = true;
    settings.trusted-users = [ "jmacdonald" ];
  };

  sops.defaultSopsFile = ../../hosts/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
