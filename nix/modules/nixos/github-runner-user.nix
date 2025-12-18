{ pkgs, ... }:
{

  sops.secrets = {
    "githubrunner/githubrunner_ed25519.pub" = {
      owner = "githubrunner";
    };
  };

  users.users.githubrunner = {
    isNormalUser = true;
    createHome = true;
    ignoreShellProgramCheck = true;
    group = "githubrunner";
    openssh.authorizedKeys.keyFiles = [
      "/run/secrets/githubrunner/githubrunner_ed25519.pub"
    ];
  };
  users.groups.githubrunner = { };
  nix.settings.trusted-users = [ "githubrunner" ];
}
