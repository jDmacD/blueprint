{ pkgs, lib, ... }:
{

  users.users.githubrunner = {
    createHome = true;
    ignoreShellProgramCheck = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/+YL3IpUNE+6Y/OzZ76adq953Mlpt7nGCLU4pZ0OiX"
    ];
  }
  // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    extraGroups = [
      "wheel"
      "githubrunner"
      "networkmanager"
    ];
    isNormalUser = true;
  };
  users.groups.githubrunner = { };
  nix.settings.trusted-users = [ "githubrunner" ];
}
