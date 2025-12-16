This is an attempt to refactor my configuration into something sane using [blueprint](https://github.com/numtide/blueprint).

I'm hoping to simplify the management of my pi fleet through the use of [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi/) now that [raspberry-pi-nix](https://discourse.nixos.org/t/what-happened-to-raspberry-pi-nix/62417) is dead.

## Blueprint Examples
- https://github.com/zimbatm/home

## Raspberry Pi Examples
- https://github.com/nvmd/nixos-raspberrypi-demo

## Building SD Images

Build an SD image for a Raspberry Pi host:

```bash
# Build SD image for a specific host
nix build .#nixosConfigurations.<hostname>.config.system.build.sdImage

# Example: Build SD image for pi01
nix build .#nixosConfigurations.pi01.config.system.build.sdImage
```

The SD image will be created in `./result/sd-image/` and can be flashed to an SD card:

```bash
# Flash to SD card (replace /dev/sdX with your SD card device)
sudo dd if=./result/sd-image/nixos-sd-image-*.img of=/dev/sdX bs=4M status=progress
sudo sync
```

**Note**: SD images are configured with a 512MB boot partition (defined in `sd-image-config.nix`) to provide sufficient space for multiple generations and prevent "No space left on device" errors during deployments.

## Cachix
Pushing customized rpi kernel to cachix
```bash
# linux_rpi-bcm2711-6.12.34-stable_20250702
# zfs-kernel-2.3.5-6.12.34-stable_20250702
nix path-info --all | grep -E "linux_rpi|linux-rpi|linux-headers-static|linux-firmware|zfs-kernel" | cachix push jdmacd
```