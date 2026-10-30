{ pkgs, ... }:
{
  sops.secrets = {
    # The runner's own token (the "token" from a registered runner's .runner
    # file), not a registration token. Read by systemd via LoadCredential, so
    # root ownership is enough for the DynamicUser service.
    "forgejo/runner/token" = { };
  };

  # https://forgejo.org/docs/latest/admin/actions/installation/packaging/
  # Migrated 2026-10-30 from services.gitea-actions-runner, which nixpkgs no
  # longer allows for forgejo-runner. The runner keeps its registration
  # (uuid + token from /var/lib/gitea-runner/picard/.runner); state now lives
  # in /var/lib/forgejo-runner/picard.
  services.forgejo-runner.instances.picard = {
    enable = true;
    settings = {
      server.connections.default = {
        url = "https://codeberg.org/";
        # Not secret; the module has no uuid_url yet.
        uuid = "fdc76cb3-7195-47ec-aa11-5cfec1009140";
      };
      runner.labels = [
        "node-22:docker://node:22-bookworm"
        "nixos-latest:docker://nixos/nix"
        "native:host"
      ];
    };
    secrets.server.connections.default.token_url = "/run/secrets/forgejo/runner/token";
    hostPackages = with pkgs; [
      bash
      coreutils
      forgejo-cli
      git
      nix
      nodejs
    ];
  };
}
