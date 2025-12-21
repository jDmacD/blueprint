# uConsole Configuration

This directory contains the NixOS configuration for the ClockworkPi uConsole - a handheld Linux terminal device built around a Raspberry Pi Compute Module 4 (CM4).

## Special Hardware Requirements

The uConsole requires specialized hardware support that is not available in the standard nixos-raspberrypi repository. This configuration uses the [oo-hardware fork](https://github.com/robertjakub/oom-hardware/tree/devel) of nixos-raspberrypi which includes:

- Custom kernel with uConsole-specific patches
- uConsole config.txt settings
- CM4-specific hardware configuration

These modules come from:
- `inputs.oom-hardware-nixos-raspberrypi` - Fork of nixos-raspberrypi with uConsole support
- `inputs.oom-hardware` - Additional uConsole hardware modules

## Why It Doesn't Use `mkRpiHost` Helper

Unlike other Raspberry Pi hosts in this repository (pi01-05, tpi01-04), the uConsole **cannot use** the standard `mkRpiHost` helper from `nix/lib/rpi-host.nix`.

**Reason:** The helper uses `inputs.nixos-raspberrypi` (the standard upstream), but the uConsole needs `inputs.oom-hardware-nixos-raspberrypi` (the OOM fork). Using both simultaneously causes a module conflict where `boot.loader.raspberryPi.enable` is declared twice.

### The Fix

The `default.nix` file uses a custom configuration that:
1. Explicitly uses `inputs.oom-hardware-nixos-raspberrypi.lib.nixosSystemFull`
2. Imports modules only from the OOM fork (`sd-image`, `usb-gadget-ethernet`)
3. Ensures consistency by passing `nixos-raspberrypi = inputs.oom-hardware-nixos-raspberrypi` in specialArgs

This ensures all nixos-raspberrypi-related modules come from a single source, avoiding conflicts.

## Building SD Image

```bash
nix build .#nixosConfigurations.uconsole.config.system.build.sdImage
```

The resulting image can be found at `./result/sd-image/nixos-sd-image-<version>-aarch64-linux.img`.

## Configuration Notes

- Root password is set to "foo" (FIXME: change this before deployment)
- Uses large console font (`ter-v32n`) suitable for the small screen
- Includes wireless tools (wirelesstools, iw) for connectivity
- State version: 26.05
