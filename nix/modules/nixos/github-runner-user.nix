{ pkgs, ... }:
{

  sops.secrets = {
    "githubrunner/githubrunner_ed25519.pub" = {
      mode = "0600";
      path = "/home/githubrunner/.ssh/githubrunner_ed25519.pub";
    };
  };

  users.users.githubrunner = {
    isNormalUser = true;
    createHome = true;
    ignoreShellProgramCheck = true;
    group = "githubrunner";
    openssh.authorizedKeys.keyFiles = [
      "~/.ssh/githubrunner_ed25519.pub"
    ];
  };
  users.groups.githubrunner = { };
  nix.settings.trusted-users = [ "githubrunner" ];
}
