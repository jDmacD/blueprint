{ pkgs, ... }:
{

  users.users.arm64builder = {
    isNormalUser = true;
    createHome = false;
    ignoreShellProgramCheck = true;
    group = "arm64builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
    ];
  };
  users.groups.arm64builder = { };
  nix.settings.trusted-users = [ "arm64builder" ]; 

}