{
  config,
  lib,
  pkgs,
  ...
}:
{

  sops.secrets."builder_ed25519" = {
    owner = "root";
    mode = "0600";
  };

  nix.buildMachines = [
    {
      hostName = "worf.jtec.xyz";
      system = "aarch64-linux";
      sshUser = "arm64builder";
      sshKey = "/run/secrets/builder_ed25519";
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
    }
  ];
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;
}
