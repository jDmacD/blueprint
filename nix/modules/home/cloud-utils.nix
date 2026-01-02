{ config, pkgs, ... }:
{
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
  ];

  sops.secrets.hetzner = {
    path = "${config.home.homeDirectory}/.config/hcloud/cli.toml";
  };

}
