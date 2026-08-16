This is jDmacD's personal NixOS/nix-darwin configuration, refactored into something
sane using [blueprint](https://github.com/numtide/blueprint). It currently manages
`worf`, `picard`, and `surface` (the actively deployed hosts), plus `lore` (macOS)
and `dev` (a disposable test VM).

The Raspberry Pi k3s fleet this repo originally managed directly via
[nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi/) (after
[raspberry-pi-nix](https://discourse.nixos.org/t/what-happened-to-raspberry-pi-nix/62417)
went dead) has since been split out into its own flake,
[`nix-pi`](https://github.com/jDmacD/nix-pi) — SD-image building and RPi
deployment now happen there, not in this repo.

See `CLAUDE.md` for actual build/deploy/secrets commands and current architecture
notes; that file is the maintained reference, this one is intentionally brief.

## Blueprint Examples
- https://github.com/zimbatm/home

## Raspberry Pi Examples (relevant to `nix-pi`, not this repo)
- https://github.com/nvmd/nixos-raspberrypi-demo