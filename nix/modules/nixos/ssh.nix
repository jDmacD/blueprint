{
  config,
  lib,
  pkgs,
  ...
}: let
in {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = false;
    };
  };
}
