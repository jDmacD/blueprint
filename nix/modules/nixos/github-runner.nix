{ pkgs, ... }:
{

  sops.secrets = {
    "githubrunner/token" = {
      owner = "githubrunner";
    };
    "githubrunner/githubrunner_ed25519" = {
      mode = "0600";
      path = "/home/githubrunner/.ssh/githubrunner_ed25519";
    };
  };

  services = {
    github-runners = {
      picard = {
        enable = true;
        replace = true;
        name = "picard";
        user = "githubrunner";
        group = "githubrunner";
        tokenFile = "/run/secrets/githubrunner/token";
        url = "https://github.com/jDmacD/blueprint-ci";
        extraPackages = [
          pkgs.deploy-rs
          pkgs.openssh
        ];
      };
    };
  };
}
