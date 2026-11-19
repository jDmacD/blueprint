{ flake, inputs, ... }:
{ config, pkgs, ... }:
{
  imports = [ inputs.multiverse.homeManagerModules.default ];

  # azure-cli 2.91.0 on unstable (2026-10-30) depends on python3.14-fabric,
  # which is marked broken. 2.89.1 is what the hosts ran before (nixpkgs
  # e7439b6). Drop the pin, and put azure-cli back in home.packages, once
  # unstable's builds.
  multiverse = {
    enable = true;
    pins.azure-cli = "2.89.1";
  };

  programs.awscli = {
    enable = true;
    settings = {
      default = {
        region = "eu-west-1";
      };
      "profile hetzner" = {
        region = "eu-west-1";
        endpoint_url = "https://hel1.your-objectstorage.com";
      };
    };
  };

  sops = {
    secrets.aws = {
      path = "${config.home.homeDirectory}/.aws/credentials";
    };
  };

  home.packages = with pkgs; [
    hcloud
    lazyhetzner
    scaleway-cli
    cloudflare-cli
  ];

  sops.secrets.hetzner = {
    path = "${config.home.homeDirectory}/.config/hcloud/cli.toml";
  };

  # Project `ephemeral` only (IAM application claude-ephemeral-builder; key
  # from BWS scaleway-claude-ephemeral, expires 2027-11-19): snapshot-builder
  # and crann's build-ephemeral.
  sops.secrets.scaleway = {
    path = "${config.home.homeDirectory}/.config/scw/config.yaml";
    # scw warns on anything but 0600 (sops-nix's default 0400 included), and
    # prints the warning on stdout, which breaks `scw … -o json | jq`.
    mode = "0600";
  };

  # Signs what nix-pi's build-push copies to the private S3 binary cache
  # (s3://jtec-nix-cache, fsn1); the public half, jtec-nix-cache-1:jTim…,
  # is in picard's trusted-public-keys.
  sops.secrets.nix_cache_signing_key = {
    path = "${config.home.homeDirectory}/.config/nix/jtec-nix-cache-1.sec";
  };

  sops.secrets.cfcli_yml = {
    path = "${config.home.homeDirectory}/.cfcli.yml";
  };

}
