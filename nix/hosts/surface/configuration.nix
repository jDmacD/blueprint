{
  inputs,
  pkgs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./nfs.nix
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    builder-arm
    builder-x86
    sops
    locale
    desktop
    lanzaboote
    tpm
    # openclaw
  ]);

  environment = {
    systemPackages = with pkgs; [
      docker-client
      cifs-utils
    ];
    variables = {
      DOCKER_HOST = "tcp://picard.lan:2375";
    };
  };

  networking = {
    hostName = "surface";
    networkmanager.enable = true;
    firewall = {
      checkReversePath = false;
      enable = true;
      allowedTCPPorts = [
        53317 # localsend
      ];
      allowedUDPPorts = [
        53317 # localsend
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
