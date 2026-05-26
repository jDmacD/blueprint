{ pkgs, ... }:
{

  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
  };
  users.groups.gitea-runner = { };

  sops.secrets = {
    "forgejo/runner/token" = {
      owner = "gitea-runner";
    };
  };
  # https://forgejo.org/docs/latest/admin/actions/installation/packaging/
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.picard = {
      enable = true;
      name = "picard";
      url = "https://codeberg.org/";
      tokenFile = "/var/run/secrets/forgejo/runner/token";
      labels = [
        "node-22:docker://node:22-bookworm"
        "nixos-latest:docker://nixos/nix"
        "native:host"
      ];
      hostPackages = with pkgs; [
        bash
        coreutils
        forgejo-cli
        git
        nix
        nodejs
      ];
      settings = { };
    };
  };
}
