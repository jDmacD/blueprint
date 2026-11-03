{
  config,
  inputs,
  ...
}:
# Plain k3s agent (no GPU) joining turing. k3s itself comes from crann's k3s
# module (package pinned through nixpkgs-multiverse by crann.k3s.version,
# kubelet memory eviction, firewall ports, Ceph prerequisites), as on the
# nix-pi fleet. picard keeps its own k3s-agent-gpu.nix for the NVIDIA wiring.
{
  imports = [ inputs.crann.modules.nixos.k3s ];

  sops.secrets."k3s/token" = {
    owner = "root";
  };

  crann.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://pi05.lan:6443";
    tokenFile = config.sops.secrets."k3s/token".path;
    # Spegel image sharing, as on the nix-pi fleet (which sets it on the server).
    embeddedRegistry.enable = true;
  };
}
