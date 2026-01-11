{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
(modulesPath + "/installer/scan/not-detected.nix")
  ]
  ++ (with inputs.self.nixosModules; [
    himmelblau
  ]);

  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    initialPassword = "password";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "sound"
      "video"
      "docker"
      "libvirtd"
    ];
    packages = [ ];
  };

  networking = {
    hostName = "dev";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
    firewall = {
      checkReversePath = false;
      enable = false;
    };
  };

  fileSystems."/" = {
    device = "/dev/sdz1";
    fsType = "ext4";
  };
  boot.loader.grub.devices = [ "/dev/sdz2" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.11"; # Did you read the comment?
}
