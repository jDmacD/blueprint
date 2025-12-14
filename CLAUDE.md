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
- `nix/devshell.nix` - Development environment
- `nix/formatter.nix` - Code formatting (deadnix + nixfmt-rfc-style)

### Host Types and Naming

The repository manages several host types with Star Trek-themed names:
- **muse**: Raspberry Pi 5 running NixOS with k3s server
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

### Host Configuration Pattern

Each host follows this structure:
```
nix/hosts/<hostname>/
├── default.nix              # Blueprint class definition
├── configuration.nix        # Main system configuration
├── hardware-configuration.nix  # Hardware-specific settings
└── users/
    └── <username>/
        └── home-configuration.nix  # User home-manager config
```

The `default.nix` sets the Blueprint class:
- `class = "nixos"` for NixOS hosts
- `class = "darwin"` for macOS hosts (implied by using darwinConfigurationFull)

### Cachix Integration

The configuration uses multiple binary caches:
- `nixos-raspberrypi.cachix.org` - Raspberry Pi packages
- `jdmacd.cachix.org` - Personal cache
- `hyprland.cachix.org` - Hyprland packages
- `nix-community.cachix.org` - Community packages

### Raspberry Pi Specifics

Raspberry Pi 5 hosts use [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) modules:
- `raspberry-pi-5.base` - Base Raspberry Pi 5 support
- `raspberry-pi-5.display-vc4` - VideoCore 4 display driver
- `sd-image` - SD card image generation

SD images can be built and flashed to SD cards for deployment.

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
