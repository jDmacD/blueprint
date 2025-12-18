{ pkgs, ... }:
{

  users.users.githubrunner = {
    isNormalUser = true;
    createHome = true;
    ignoreShellProgramCheck = true;
    group = "githubrunner";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/+YL3IpUNE+6Y/OzZ76adq953Mlpt7nGCLU4pZ0OiX"
    ];
  };
  users.groups.githubrunner = { };
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "githubrunner" ];
}
