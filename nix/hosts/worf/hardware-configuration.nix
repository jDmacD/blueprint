{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0"; # either ens3 (amd64) or enp1s0 (arm64)
      networkConfig.DHCP = "ipv4";
      routes = [
        {Gateway = "fe80::1";}
        # {routeConfig.Gateway = "fe80::1";}
      ];
    };
  };

  networking.useDHCP = false;
}
