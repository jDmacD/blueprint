{
  flake,
  inputs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.host-shared
    inputs.self.nixosModules.ui
  ];

  environment.systemPackages = [ ];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "riker";
  };

  system.stateVersion = "25.05";
}
