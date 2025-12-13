{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = with inputs.self.nixosModules; [
    ssh
    host-shared
    homebrew
    stylix
    fonts
  ];

  users.users.jmacdonald.home = "/Users/jmacdonald";

  environment.systemPackages = [
  ];

  networking = {
    hostName = "lore";
    localHostName = "lore";
    domain = "lan";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
