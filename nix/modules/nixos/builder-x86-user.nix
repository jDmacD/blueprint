{ pkgs, ... }:
{

  users.users.x86builder = {
    isNormalUser = true;
    createHome = false;
    ignoreShellProgramCheck = true;
    group = "x86builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
    ];
  };
  users.groups.x86builder = { };
  nix.settings.trusted-users = [ "x86builder" ]; 

}