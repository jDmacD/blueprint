{ pkgs, ... }:
{

  sops.secrets."github/token" = { };

  services = {
    github-runners = {
      runner = {
        enable = true;
        name = "runner";
        tokenFile = "/run/secrets/github/token";
        url = "https://github.com/jDmacD/blueprint-ci";
      };
    };
  };
}
