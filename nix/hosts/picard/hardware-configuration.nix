{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  # boot.kernelPackages = pkgs.linuxPackages_6_12;
  # For gamescope https://wiki.archlinux.org/title/Gamescope
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  fileSystems."/export/calibre-library" = {
    device = "/mnt/calibre-library";
    options = [ "bind" ];
  };

  # Disabled because we're using a bridge (vmbr0) for libvirt/virt-manager
  # DHCP is explicitly configured per-interface in configuration.nix
  networking.useDHCP = lib.mkDefault false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
