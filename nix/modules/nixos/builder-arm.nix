{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.buildMachines = [
    {
      hostName = "worf.jtec.xyz";
      system = "aarch64-linux";
      sshUser = "arm64builder";
      sshKey = "/run/secrets/armbuilder_ed25519";
      protocol = "ssh-ng";
      # if the builder supports building for multiple architectures,
      # replace the previous line by, e.g.
      # systems = ["x86_64-linux" "aarch64-linux"];
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
