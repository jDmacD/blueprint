{ pkgs, ... }:
{

  sops.secrets."github/token" = { };

  services = {
    github-runners = {
      picard = {
        enable = true;
        name = "picard";
        tokenFile = "/run/secrets/github/token";
        url = "https://github.com/jDmacD/blueprint-ci";
        extraPackages = [
          pkgs.deploy-rs
        ];
      };
    };
  };
}
