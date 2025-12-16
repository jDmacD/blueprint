{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = with inputs.self.darwinModules; [
    sops
    stylix
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

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
