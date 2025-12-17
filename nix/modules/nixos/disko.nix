{
  config,
  lib,
  pkgs,
  ...
}:
let
  partmover = pkgs.pkgs.writeShellScriptBin "partmover" ''
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /nix/ /mnt/nix
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /var/ /mnt/var
  '';
in
{
  environment.systemPackages = with pkgs; [
    partmover
  ];

  fileSystems = {
    "/mnt/nix" = {
      device = "/dev/disk/by-partlabel/disk-external-nix";
      fsType = "ext4";
      options = ["noatime"];
    };
    "/mnt/var" = {
      device = "/dev/disk/by-partlabel/disk-external-var";
      fsType = "ext4";
      options = ["noatime"];
    };
  };




}
