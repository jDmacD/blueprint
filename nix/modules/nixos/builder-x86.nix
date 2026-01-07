{
  ...
}:
{

  sops.secrets."builder_ed25519" = {
    owner = "root";
    mode = "0600";
  };

  nix.buildMachines = [
    {
      hostName = "picard.lan";
      system = "x86_64-linux";
      sshUser = "builder";
      sshKey = "/run/secrets/builder_ed25519";
      protocol = "ssh-ng";
      maxJobs = 10;
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
  # optional, useful when the builder has a faster internet connection than yours
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
}
