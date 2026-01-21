{
  pkgs,
  ...
}:
pkgs.writeShellScriptBin "cachix-update" ''
  nix path-info --all \
    | grep -E "linux_rpi|linux-rpi|linux-headers-static|linux-firmware|zfs-kernel|linux-config|himmelblau|bind|jemalloc" \
    | ${pkgs.cachix}/bin/cachix push jdmacd
''
