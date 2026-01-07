# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS/nix-darwin configuration repository using [Blueprint](https://github.com/numtide/blueprint) for managing multiple systems including Raspberry Pi fleet, Linux workstations, and macOS machines. The configuration focuses on managing a Kubernetes cluster (k3s) across Raspberry Pi nodes with secrets management via SOPS.

## Common Commands

### Building and Deploying

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Build darwin configuration (macOS)
nix build .#darwinConfigurations.lore.system

# Build SD image for Raspberry Pi
nix build .#nixosConfigurations.muse.config.system.build.sdImage

# Switch to new configuration (on target host)
sudo nixos-rebuild switch --flake .

# Switch darwin configuration (macOS)
darwin-rebuild switch --flake .
```

### Formatting

```bash
# Format all Nix files in the project
nix fmt

# Format specific files/directories
nix fmt nix/hosts/
```

### Development Shell

```bash
# Enter development shell (direnv will auto-load if configured)
nix develop

# Or manually
direnv allow
```

### Secrets Management (SOPS)

```bash
# Edit secrets for a specific host
sops nix/hosts/<hostname>/secrets.yaml

# Edit shared secrets
sops nix/hosts/secrets.yaml
sops nix/secrets/personal.yaml
sops nix/secrets/heanet.yaml
```

## Architecture

### Blueprint Structure

This repository uses Blueprint with a `nix/` prefix convention:
- `flake.nix` - Main flake configuration with all inputs
- `nix/hosts/` - Per-host configurations
- `nix/modules/nixos/` - NixOS system modules (shared configurations)
- `nix/modules/home/` - home-manager modules (user configurations)
- `nix/lib/` - Shared helper functions
  - `rpi-host.nix` - Helper for creating Raspberry Pi host configurations
- `nix/devshell.nix` - Development environment
- `nix/formatter.nix` - Code formatting (deadnix + nixfmt-rfc-style)

**Blueprint's perSystem:**
Blueprint provides a `perSystem` argument to modules, which allows accessing per-system outputs from flake inputs. For example, `perSystem.nixpkgs-25-05.pkgs` is equivalent to `inputs.nixpkgs-25-05.legacyPackages.<system>`. This is used in modules like `k3s-agent.nix` to access packages from specific nixpkgs versions.

### Host Types and Naming

The repository manages several host types with Star Trek-themed names:

**Raspberry Pi Fleet (k3s cluster):**
- **pi01, pi02, pi03**: Raspberry Pi 4B - k3s agents
- **pi04, pi05**: Raspberry Pi 5 - k3s agents
- **tpi01, tpi02, tpi03, tpi04**: Compute Module 4 (CM4) - tpi01 is control plane, others are agents

**Other Hosts:**
- **riker**: x86_64 Linux workstation with UI (Hyprland)
- **lore**: macOS (aarch64-darwin) with nix-darwin and homebrew
- **worf**: VPS/cloud host with disko for disk management

### Module System

**NixOS Modules** (`nix/modules/nixos/`):
- `host-shared.nix` - Core configuration for all hosts (Nix settings, caching, Stylix)
- `k3s-server.nix` - Kubernetes control plane configuration
- `k3s-agent.nix` - Kubernetes worker node configuration
- `rpi5.nix` - Raspberry Pi 5 specific hardware setup
- `ui.nix` - Desktop environment (Hyprland)
- `hyprland.nix` - Hyprland window manager configuration
- `ssh.nix` - SSH server configuration
- `users.nix` - User account management
- `homebrew.nix` - macOS Homebrew integration
- `eduvpn.nix` - EduVPN client with NetworkManager OpenVPN support
- `vpn-split-tunnel.nix` - Automatic VPN split tunneling for local network access

**home-manager Modules** (`nix/modules/home/`):
- `home-shared.nix` - Base home configuration (devbox, pre-commit, sops, ssh-agent)
- `terminal.nix` - Terminal configuration
- `firefox.nix` - Firefox browser setup
- `vscode.nix` - VSCode configuration
- `kubernetes-utils.nix` - k8s CLI tools and utilities
- `personal.nix` - Personal development tools
- `work.nix` - Work-specific tools

### Kubernetes (k3s) Configuration

The k3s cluster is configured with:
- Flannel and kube-proxy disabled (likely using Cilium)
- Traefik disabled (custom ingress)
- ServiceLB disabled
- Custom TLS SAN for `.lan` domain names
- Firewall ports: 6443 (API), 10250 (metrics), 4240 (Cilium health), 8472 (Flannel/VXLAN)

K3s agents connect using a token stored in `/var/run/secrets/k3s/token` (managed via SOPS).

### Secrets Management

SOPS is configured with age encryption using per-host age keys. Secret files follow patterns:
- `nix/secrets/personal.yaml` - Personal secrets (encrypted with personal key)
- `nix/secrets/heanet.yaml` - Heanet-specific secrets
- `nix/hosts/secrets.yaml` - Shared host secrets (all host keys)
- `nix/hosts/<hostname>/secrets.yaml` - Per-host secrets

Age keys for hosts: hel-1, picard, surface, lore, worf (defined in `.sops.yaml`).

### VPN Split Tunneling

The `vpn-split-tunnel` module enables automatic split tunneling for VPN connections, allowing simultaneous access to work VPN resources and local network resources (like the k3s cluster at `.lan` domains).

**How it works:**
- NetworkManager dispatcher script detects when EduVPN connections are established
- Automatically configures the VPN connection to not become the default route
- Ignores routes pushed by the VPN server that conflict with local networks
- Configures split DNS so local DNS (192.168.178.1) is used for `.lan` domains
- Deletes any conflicting routes for local network ranges (192.168.0.0/16, 10.0.0.0/8)
- Local network traffic and DNS queries stay on the local interface
- Only work-specific networks and domains route through the VPN tunnel

**Important:** After first deployment, disconnect and reconnect the VPN for DNS settings to take effect.

**Usage:**
```nix
# In host configuration
networking.vpnSplitTunnel.enable = true;
```

The module automatically detects VPN connections matching `*eduvpn*` (case-insensitive) and applies split tunneling configuration. No manual intervention needed after deployment.

**Package:** `nix/packages/vpn-split-tunnel/` - Contains the NetworkManager dispatcher script

### Host Configuration Pattern

Each host follows this structure:
```
nix/hosts/<hostname>/
├── default.nix              # Optional: Blueprint class definition (required for Raspberry Pi hosts)
├── configuration.nix        # Main system configuration
├── hardware-configuration.nix  # Hardware-specific settings (optional)
└── users/
    └── <username>/
        └── home-configuration.nix  # User home-manager config
```

**Standard hosts** (worf, riker, lore) don't need `default.nix` - Blueprint automatically discovers them via `configuration.nix` or `darwin-configuration.nix`.

**Raspberry Pi hosts** require `default.nix` using the `mkRpiHost` helper from `nix/lib/rpi-host.nix`:
```nix
{ flake, inputs, ... }:
let
  mkRpiHost = import inputs.self.lib.rpi-host {
    inherit inputs flake;
  };
in
mkRpiHost {
  board = "4";  # or "5" for RPi 5
  rpiModules = [ "sd-image" "usb-gadget-ethernet" ];
  extraModules = [ ./configuration.nix ];
}
```

This is necessary because Raspberry Pi hosts use `nixos-raspberrypi.lib.nixosSystemFull` which applies RPi-specific overlays. The helper abstracts the boilerplate while keeping `configuration.nix` consistent with other hosts.

### Cachix Integration

The configuration uses multiple binary caches:
- `nixos-raspberrypi.cachix.org` - Raspberry Pi packages
- `jdmacd.cachix.org` - Personal cache
- `hyprland.cachix.org` - Hyprland packages
- `nix-community.cachix.org` - Community packages

### Raspberry Pi Specifics

All Raspberry Pi hosts use [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) integration via the `nix/lib/rpi-host.nix` helper.

**Available nixos-raspberrypi modules:**
- `raspberry-pi-4.base` - Base Raspberry Pi 4B/CM4 support
- `raspberry-pi-5.base` - Base Raspberry Pi 5 support
- `raspberry-pi-5.page-size-16k` - 16K page size for RPi 5
- `raspberry-pi-5.display-vc4` - VideoCore 4 display driver
- `raspberry-pi-5.display-rp1` - RP1 display driver
- `sd-image` - SD card image generation
- `usb-gadget-ethernet` - USB gadget mode for networking

**Why Raspberry Pi hosts need special handling:**
- Cannot use global nixos-raspberrypi overlays (causes conflicts with non-RPi hosts)
- Must use `nixos-raspberrypi.lib.nixosSystemFull` to apply RPi overlays in isolated context
- The `mkRpiHost` helper in `nix/lib/rpi-host.nix` abstracts this complexity
- Helper also provides `perSystem` for accessing packages from alternate nixpkgs versions (e.g., `nixpkgs-25-05`)

**Building SD images:**
```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.sdImage
```

SD images can be flashed to SD cards for deployment.

## Key Dependencies

- **blueprint** - Configuration organization framework
- **nix-darwin** - macOS system management
- **home-manager** - User environment management
- **sops-nix** - Secrets management
- **disko** - Declarative disk partitioning
- **hyprland** - Wayland compositor
- **stylix** - System-wide theming
- **nixos-raspberrypi** - Raspberry Pi hardware support
- **nur** - Nix User Repository

## Important Conventions

- All Nix files should be formatted with `nixfmt-rfc-style` and checked with `deadnix`
- Secrets must never be committed unencrypted - always use SOPS
- System state versions are pinned per-host and should not be changed after initial installation
- k3s cluster token is stored in SOPS and deployed to `/var/run/secrets/k3s/token`
- Host platform is explicitly set in each configuration (`nixpkgs.hostPlatform`)
- Modules should be imported using `inputs.self.nixosModules.<name>` or `inputs.self.homeModules.<name>` syntax rather than relative paths for consistency
- `networking.hostName` is set in each host's `configuration.nix`, not in `default.nix` helpers

## Test Building
```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel 
```

## Remote Deployment

Deploy to remote Raspberry Pi hosts using:
```bash
nixos-rebuild --use-remote-sudo --target-host <user>@<hostname>.lan --flake .#<hostname> switch
```

Example:
```bash
nixos-rebuild --use-remote-sudo --target-host jmacdonald@pi01.lan --flake .#pi01 switch
```

### Troubleshooting Boot Partition Full

Raspberry Pi hosts have a 128MB FAT32 boot partition (`/boot/firmware`) that can fill up with old bootloader files and generations, causing deployment failures with errors like:

```
cp: error writing '/boot/firmware/start4cd.elf.tmp.XXXX': No space left on device
Failed to install bootloader
```

**Quick fix:**

```bash
# SSH into the affected host
ssh <user>@<hostname>.lan

# Remove temporary files
sudo rm -rf /boot/firmware/*.tmp* /boot/firmware/nixos/*.tmp.*

# Delete old system generations (keeps current + recent)
sudo nix-collect-garbage --delete-older-than 1d

# Delete specific old generations
sudo nix-env --delete-generations --profile /nix/var/nix/profiles/system 7 8 9

# Remove old boot generation directories
sudo rm -rf /boot/firmware/nixos/*-default

# Verify space is available (should have 40MB+ free)
df -h /boot/firmware
```

**Prevention:**

1. Run `sudo nix-collect-garbage --delete-old` regularly on Raspberry Pi hosts
2. Consider limiting boot generations in configuration (currently installs default + last 3 generations)
3. If rebuilding SD images, increase boot partition size to 256MB or 512MB in disk configuration
