{
  config,
  lib,
  pkgs,
  ...
}:
let
  bootstrapper-5 = pkgs.pkgs.writeShellScriptBin "bootstrapper-5" ''
    nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.11.0 -- --mode disko /etc/disko/configuration.nix
    nix-store --gc
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /var/ /mnt/var
  '';
  bootstrapper-cm4 = pkgs.pkgs.writeShellScriptBin "bootstrapper-cm4" ''
    nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.11.0 -- --mode disko /etc/disko/configuration.nix
    nix-store --gc
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /nix/ /mnt/nix
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /var/ /mnt/var
  '';
in
{
  environment.systemPackages = with pkgs; [
    bootstrapper-5
    bootstrapper-cm4
  ];

  environment.etc."disko/configuration.nix" = {
    text = builtins.readFile ./disk-configuration.nix;
  };
}
