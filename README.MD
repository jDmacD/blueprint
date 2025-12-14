This is an attempt to refactor my configuration into something sane using [blueprint](https://github.com/numtide/blueprint).

I'm hoping to simplify the management of my pi fleet through the use of [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi/) now that [raspberry-pi-nix](https://discourse.nixos.org/t/what-happened-to-raspberry-pi-nix/62417) is dead.

## Blueprint Examples
- https://github.com/zimbatm/home

## Raspberry Pi Examples
- https://github.com/nvmd/nixos-raspberrypi-demo

## Cachix
Pushing customized rpi kernel to cachix
```bash
# linux_rpi-bcm2711-6.12.34-stable_20250702
# zfs-kernel-2.3.5-6.12.34-stable_20250702
nix path-info --all | grep -E "linux_rpi|linux-rpi|linux-headers-static|linux-firmware|zfs-kernel" | cachix push jdmacd
```