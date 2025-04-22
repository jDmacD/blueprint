{ pkgs, ... }:
{

  users.users.jmacdonald.isNormalUser = true;

  # you can check if host is darwin by using pkgs.stdenv.isDarwin
  environment.systemPackages = [
    pkgs.btop
  ] ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.xbar ]);
}