/*
  This is for the cm4s with connected disks

  1. disable the ./disk-configuration.nix import and include partition-syncer
  2. build an image and push it to the turingpi see scripts/cm4-builder.sh
  3. flash `tpi flash -l -i /mnt/sdcard/<node>.img -n <number>`
  4. boot
  5. re-enable the ./disk-configuration.nix import
  6. !!!!! perform a rebuild using boot `nixos-rebuild --target-host jmacdonald@tpi04.lan --use-remote-sudo --flake .#tpi04 boot`
  7. ssh into the node and run `sudo partsync`
  8. reboot
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  partsync = pkgs.pkgs.writeShellScriptBin "partsync" ''
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /nix/ /mnt/nix
    ${pkgs.rsync}/bin/rsync --archive --hard-links --acls --one-file-system --verbose /var/ /mnt/var
  '';
in
{
  environment.systemPackages = with pkgs; [
    partsync
  ];

  fileSystems = {
    "/mnt/nix" = {
      device = "/dev/disk/by-partlabel/disk-external-nix";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt/var" = {
      device = "/dev/disk/by-partlabel/disk-external-var";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

}
