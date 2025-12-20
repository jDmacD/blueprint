{ pkgs, perSystem, ... }:
{

  sops.secrets = {
    "githubrunner/token" = {
      owner = "githubrunner";
    };
    "githubrunner/githubrunner_ed25519" = {
      mode = "0400";
      owner = "githubrunner";
      group = "githubrunner";
      path = "/home/githubrunner/.ssh/githubrunner_ed25519";
    };
  };

  services = {
    github-runners = {
      picard = {
        enable = true;
        replace = true;
        name = "picard-01";
        user = "githubrunner";
        group = "githubrunner";
        tokenFile = "/run/secrets/githubrunner/token";
        url = "https://github.com/jDmacD/blueprint-ci";
        extraPackages = [
        ]
        ++ (with perSystem.self; [
          fleet-deploy
          cachix-update
          flake-lock-push
        ]);
      };
    };
  };
}
