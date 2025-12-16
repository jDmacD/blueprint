{
  config,
  lib,
  pkgs,
  ...
}:
let
  bootstrapper = pkgs.pkgs.writeShellScriptBin "bootstrapper" ''
    nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.11.0 -- --mode disko /etc/disko/configuration.nix
    nix-store --gc
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /nix/ /mnt/nix
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /var/ /mnt/var
  '';
in
{
  environment.systemPackages = with pkgs; [
    bootstrapper
  ];

}
