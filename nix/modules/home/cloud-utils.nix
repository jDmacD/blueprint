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
    cloudflare-cli
  ];

  sops.secrets.hetzner = {
    path = "${config.home.homeDirectory}/.config/hcloud/cli.toml";
  };

  sops.secrets.cfcli_yml = {
    path = "${config.home.homeDirectory}/.cfcli.yml";
  };

}
