# nix/hosts/lwh-hotapril/configuration.nix
# Dell Latitude 5310, formerly a HEAnet work laptop (git.heanet.ie
# james.macdonald/blueprint), now jDmacD's own. A thin niri/noctalia desktop
# that is also a schedulable turing k3s agent. The disk layout and
# stateVersion are carried over from that install, which was switched in
# place rather than reinstalled.
{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    sops
    locale
    desktop
    tpm
    k3s-agent
  ])
  ++ [
    inputs.crann.modules.nixos.remote-builder
  ];

  # Pin the node to the wired NIC behind the dock (Kea reservation .25). If
  # k3s registered on Wi-Fi (wlo1, .131) the node IP would move whenever the
  # dock is unplugged and Cilium would break for this node. Off the dock the
  # desktop keeps working on Wi-Fi; the node goes NotReady until redocked.
  # Cilium's `devices` for this node (eno2) come from a CiliumNodeConfig in
  # catalogue, since the global list is only end0/enp3s0.
  crann.k3s.extraFlags = [ "--node-ip=192.168.178.25" ];

  # Same client setup as surface: builds go to worf (arm) and picard (x86),
  # both running crann.remote-builder.server, with the shared builder_ed25519
  # identity. publicHostKey values are copied from surface's configuration.
  sops.secrets."builder_ed25519" = {
    owner = "root";
    mode = "0600";
  };
  sops.secrets."bitwarden_secret" = {
    owner = "jmacdonald";
  };
  crann.remote-builder.enable = true;
  crann.remote-builder.machines = [
    {
      hostName = "worf.jtec.xyz";
      system = "aarch64-linux";
      sshKey = config.sops.secrets."builder_ed25519".path;
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUdyalVZWDlpdXc2aEw3WXVLSDA3cUFieWs5Z0YxcjFrOEx1UWQwT2ZRaHQK";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
    {
      hostName = "picard.lan";
      system = "x86_64-linux";
      sshKey = config.sops.secrets."builder_ed25519".path;
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUVVdXg4NWh3dkpqeXhSNk9meWZheHhEbDdkeWNMbUVmSWJIYXFrQTgxbUcK";
      maxJobs = 10;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    bws
  ];

  programs.nix-ld.enable = true;

  networking = {
    hostName = "lwh-hotapril";
    networkmanager.enable = true;
    # The firewall stays off: crann.k3s disables it, as on picard.
  };

  services = {
    # Thunderbolt dock.
    hardware.bolt.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
