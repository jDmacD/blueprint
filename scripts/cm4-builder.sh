#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash zstd

for host in tpi01 tpi02 tpi03; do
  echo "Building $host..."
  nix build .#nixosConfigurations.$host.config.system.build.toplevel
  sleep 5s
  zstd -d ./result/sd-image/nixos-sd-image-rpi4-uboot.img.zst -o $host.img
  scp $host.img root@turingpi.lan:/mnt/sdcard/$host.img
done