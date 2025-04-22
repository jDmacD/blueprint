{ flake, inputs, perSystem, ... }:
{
  imports = [ inputs.self.nixosModules.host-shared ];

  environment.systemPackages = [];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "24.05";
}