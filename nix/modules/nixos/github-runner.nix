{ pkgs, ... }:
{

  sops.secrets."github/token" = { };

  services = {
    github-runners = {
      picard = {
        enable = true;
        name = "picard";
        user = "githubrunner";
        group = "githubrunner";
        tokenFile = "/run/secrets/github/token";
        url = "https://github.com/jDmacD/blueprint-ci";
        extraPackages = [
          pkgs.deploy-rs
          pkgs.openssh
        ];
      };
    };
  };

  users.users.githubrunner = {
    isNormalUser = true;
    createHome = false;
    ignoreShellProgramCheck = true;
    group = "githubrunner";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
    ];
  };
  users.groups.githubrunner = { };
  nix.settings.trusted-users = [ "githubrunner" ];
}
