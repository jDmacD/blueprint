{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = [ inputs.self.nixosModules.host-shared ];

  users.users.jmacdonald.home = "/Users/jmacdonald";

  environment.systemPackages = [
  ];

  networking = {
    hostName = "lore";
    localHostName = "lore";
    domain = "lan";
  };

  services.openssh = {
    enable = true;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 6;
}
