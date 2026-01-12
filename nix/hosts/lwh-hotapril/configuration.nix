# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-configuration.nix
    inputs.disko.nixosModules.disko
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    docker
    builder-x86
    sops
    locale
    desktop
    eduvpn
    vpn-split-tunnel
    # himmelblau
    tpm
    # iperf
  ]);

  services.himmelblau.domainPreset = "jtec";

  networking = {
    hostName = "lwh-hotapril";
    networkmanager.enable = true;
    vpnSplitTunnel.enable = false;
    firewall = {
      checkReversePath = false;
      enable = true;
      #  https://discourse.nixos.org/t/nixos-docker-and-the-host-network/11130
      allowedTCPPorts = [
        9193
        80
        3000
        3389
      ];
    };
  };

  hardware = {
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
    };
    enableAllFirmware = true;
  };

  services = {
    hardware.bolt.enable = true;
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
