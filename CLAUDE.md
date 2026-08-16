# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS/nix-darwin configuration repository using [Blueprint](https://github.com/numtide/blueprint) for managing a small set of personal machines: **worf**, **picard**, and **surface** are the actively deployed/critical hosts, plus **lore** (macOS) and **dev** (disposable test VM). Secrets are managed via SOPS throughout.

The Raspberry Pi fleet (k3s cluster) that this repo originally managed was split out into its own standalone flake, [`nix-pi`](https://github.com/jDmacD/nix-pi) (`~/Code/nix-pi` locally) — it no longer lives here; see "Former Raspberry Pi Fleet" below. **picard** still participates in that cluster as a k3s agent (`k3s-agent-gpu` module), but the cluster's control plane and other nodes are defined in `nix-pi`, not in this repo.

This repo is also mid-migration: reusable modules are being ported out into a companion library flake, [crann](https://github.com/jDmacD/crann), and re-consumed here as a flake input — see "crann Migration" below. Treat this file as a snapshot that can drift from the actual module wiring; when in doubt, grep `nix/hosts/*/configuration.nix` and `nix/hosts/*/users/*/home-configuration.nix` for what a host actually imports rather than trusting this doc's module lists.

## Common Commands

### Building and Deploying

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Build darwin configuration (macOS)
nix build .#darwinConfigurations.lore.system

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
sops nix/secrets/work.yaml
sops nix/secrets/turing.yaml
```

## Architecture

### Blueprint Structure

This repository uses Blueprint with a `nix/` prefix convention:
- `flake.nix` - Main flake configuration with all inputs
- `nix/hosts/` - Per-host configurations
- `nix/modules/nixos/` - NixOS system modules (shared configurations)
- `nix/modules/home/` - home-manager modules (user configurations)
- `nix/lib/` - Shared helper functions (sops, stylix, greetd, wallpapers)
- `nix/devshell.nix` - Development environment
- `nix/formatter.nix` - Code formatting (deadnix + nixfmt-rfc-style)

**Blueprint's perSystem:**
Blueprint provides a `perSystem` argument to modules, which allows accessing per-system outputs from flake inputs. For example, `perSystem.nixpkgs-25-05.pkgs` is equivalent to `inputs.nixpkgs-25-05.legacyPackages.<system>`. This is used in modules like `k3s-agent-gpu.nix` to access packages from specific nixpkgs versions.

### Host Types and Naming

The repository manages hosts under `nix/hosts/`, mostly with Star Trek-themed
names. Current hosts (verify against `ls nix/hosts/` — this list drifts):

- **picard**: x86_64 Linux home server/hypervisor (libvirtd, k3s-agent-gpu, docker,
  NFS, Sunshine game streaming) with a niri desktop. Critical/actively deployed.
- **surface**: x86_64 Linux laptop (Surface device: lanzaboote secure boot, TPM,
  opendeck) with a niri desktop. Critical/actively deployed.
- **worf**: VPS/cloud host (`worf.jtec.xyz`) with disko for disk management, no
  desktop. Critical/actively deployed.
- **lore**: macOS (aarch64-darwin) with nix-darwin and homebrew. Not yet migrated
  to crann (see "crann Migration" below).
- **dev**: disposable/scratch x86_64 Linux VM (himmelblau module only) — not a
  desktop host, minimal configuration, not documented further here.

`riker` (a former Hyprland workstation) no longer exists in this repo.

### Former Raspberry Pi Fleet

This repo used to also manage a Raspberry Pi k3s fleet (`pi01`–`pi05`,
`tpi01`–`tpi04`) directly, via `nixos-raspberrypi.lib.nixosSystemFull` and a
`mkRpiHost` helper (`nix/lib/rpi-host.nix`). That fleet has been fully split out
into a standalone flake, [`nix-pi`](https://github.com/jDmacD/nix-pi) — none of
those host directories, the `rpi-host.nix` helper, or the RPi SD-image workflow
exist in this repo anymore. The `nixos-raspberrypi` flake input is still declared
in `flake.nix` but is otherwise unused here; `flake.nix`'s `deploy.nodes` also
still lists `pi01`–`pi05`/`tpi01`–`tpi04` as deploy targets even though no
matching `nixosConfigurations` exist — those entries are dead and would fail if
invoked. For actual RPi fleet docs, see `nix-pi`'s own `CLAUDE.md`.

### Module System

**NixOS Modules** (`nix/modules/nixos/`) — non-exhaustive; see the directory for the
full, fast-moving fleet/service module set (acme, docker, forgejo-runner, github-runner,
himmelblau, k3s-agent-gpu, and similar):
- `host-shared.nix` - Core configuration for all hosts (Nix settings, caching, Stylix)
- `ssh.nix` - SSH server configuration
- `users.nix` - User account management
- `homebrew.nix` - macOS Homebrew integration
- `eduvpn.nix` - EduVPN client with NetworkManager OpenVPN support
- `vpn-split-tunnel.nix` - Automatic VPN split tunneling for local network access
- `desktop.nix` - GUI host aggregator (peripherals, fonts, gdm, printing) that pulls
  niri/noctalia/stylix in from **crann** — see "crann Migration" below

**home-manager Modules** (`nix/modules/home/`):
- `home-shared.nix` - Base home configuration (devbox, pre-commit, sops, ssh-agent)
- `terminals.nix` / `terminal-utils.nix` - Terminal emulators + CLI utilities (legacy;
  superseded by crann's `terminal` module on picard/worf/surface — see below)
- `firefox.nix` - Firefox browser setup
- `kubernetes-utils.nix` - k8s CLI tools and utilities (legacy; superseded by crann's
  `kubernetes` module on picard/surface)
- `git-utils.nix` - gh/lazygit/pre-commit (legacy; superseded by crann's `git` module
  on picard/surface)
- `personal.nix` - Personal development tools + git identity
- `work.nix` - Work-specific tools (currently unused by any host)
- `desktop.nix` - Desktop aggregator that pulls noctalia/vscode in from **crann**

**darwin Modules** (`nix/modules/darwin/`) - undocumented elsewhere, so listed in
full: `host-shared.nix`, `sops.nix`, `stylix.nix` — lore's equivalent of the
NixOS `host-shared.nix`/`sops.nix` base config, plus a local (non-crann) stylix
module for the darwin host.

### crann Migration

Reusable modules are being ported out of this repo and into
[crann](https://github.com/jDmacD/crann) (`~/Code/crann` locally), a separate
flake-parts/dendritic library flake, then re-imported here via the `crann` flake
input (`inputs.crann.modules.<class>.<name>`). See crann's own `CLAUDE.md` for its
conventions.

**Migration state is uneven per host, not a blanket switch** — check each host's
`configuration.nix`/`home-configuration.nix` for its actual `inputs.crann.modules.*`
imports rather than trusting a summary. As of 2026-08-16:

- **picard** (NixOS + home): `desktop` module pulls in crann's `niri`/`noctalia`/`stylix`
  at the NixOS level; `crann.steam` (NixOS, picard-only); home-manager: `git`,
  `kubernetes`, `shells`, `terminal`. Still on **local** `ai-utils`
  (`inputs.self.homeModules.ai-utils`), not crann's.
- **surface** (NixOS + home): same NixOS-level `desktop` module (niri/noctalia/stylix)
  plus the new `crann.nix` wrapper (`inputs.crann.modules.nixos.optnix`); home-manager:
  `git`, `kubernetes`, `shells`, `terminal`, `nix-utils`, `optnix`, `obsidian`, and
  **`ai-utils`** — surface is currently the only host on crann's `ai-utils` module
  (drives the `claude-code`/`claude-obsidian` context injection).
- **worf** (NixOS + home, headless — no desktop stack at all): home-manager only,
  `shells` and `terminal`. No `git`/`kubernetes`/niri/noctalia/stylix/vscode on worf.
- **lore** (darwin): not migrated — still uses the original local
  `git-utils.nix`/`kubernetes-utils.nix`/`shells.nix`/`terminals.nix`/`terminal-utils.nix`/
  `vscode.nix` — don't delete those files until lore is switched over too.

picard's Sunshine/Hyprland game-streaming setup (`sunshine.nix`,
`hyprland-sunshine.nix`) is staying local — porting it raises a separate
Hyprland-in-crann design question. `nix/modules/nixos/crann.nix` (a thin wrapper
enabling `crann.optnix`) is new/uncommitted as of 2026-08-16 and not yet used
outside surface.

**Gotchas learned the hard way:**
- `crann.niri.enable = true;` must be set explicitly at the **NixOS** level (in
  `nixos/desktop.nix`). Setting only `crann.niri.extraSettings` does nothing — the
  entire module (portal, session, polkit, keyring, `xdg.portal.enable`) is gated
  behind `lib.mkIf cfg.enable`. A missing `enable` here silently breaks
  `xdg.portal.enable`, which then fails any Flatpak (`opendeck.nix`) or per-user
  portal assertion — a confusing failure mode far from the actual cause.
- Do **not** set `crann.niri.enable` at the **home-manager** level for
  NixOS-integrated hosts (picard/surface/worf) — that option only exists if you
  import crann's standalone `homeManager.niri` module, which you shouldn't for these
  hosts (double-declares `programs.niri.*`). niri's home config is injected
  automatically via `home-manager.sharedModules` from the NixOS-level module.
- After crann changes land on its `main` branch, run `nix flake lock --update-input
  crann` here to pick them up — local edits in `~/Code/crann` don't reach this repo
  until pushed and the lock is updated.

### Kubernetes (k3s) Configuration

This repo does **not** define the k3s cluster's control plane or server-side flags
(flannel/traefik/servicelb disabling, TLS SANs, etc.) — that configuration now
lives in the separate [`nix-pi`](https://github.com/jDmacD/nix-pi) flake, on the
`tpi01` control-plane node. This repo only defines **picard** as a k3s **agent**
(`nix/modules/nixos/k3s-agent-gpu.nix`), which:
- Joins the cluster at `https://tpi01.lan:6443` using a token from
  `sops.secrets."k3s/token"` (SOPS-managed, resolves to `/run/secrets/k3s/token`).
- Opens firewall ports 6443 (API), 10250 (metrics), 4240 (Cilium health), 443, 80
  TCP and 8472 (Flannel/VXLAN) UDP, with the rest of the host firewall disabled.
- Adds NVIDIA container-toolkit wiring (GPU workloads via the `nvidia`
  RuntimeClass) — this module is GPU-specific, not a generic k3s-agent module.

For the cluster's actual server-side behavior, read `nix-pi`'s own `CLAUDE.md`
directly rather than inferring it from this repo.

### Secrets Management

SOPS is configured with age encryption using per-host age keys. Secret files follow patterns:
- `nix/secrets/personal.yaml` - Personal secrets (encrypted with personal key)
- `nix/secrets/work.yaml` - Work secrets (encrypted with work key; includes heanet
  identity/SSH secrets such as `heanet_id_rsa`, consumed by `nix/modules/home/work.nix`)
- `nix/secrets/turing.yaml` - Turing Pi / RPi-fleet-adjacent secrets (personal key)
- `nix/hosts/secrets.yaml` - Shared host secrets (all host keys)
- `nix/hosts/<hostname>/secrets.yaml` - Per-host secrets

Age keys are defined in `.sops.yaml`. It still lists keys for the former RPi fleet
hosts (`pi01`–`pi05`, `tpi01`–`tpi04`, `uconsole`) alongside the currently-relevant
`hel-1`, `picard`, `surface`, `lore`, `worf` — those RPi entries are stale leftovers
from before the `nix-pi` split, not evidence those hosts are still managed here.

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
├── configuration.nix        # Main system config (or darwin-configuration.nix for lore)
├── hardware-configuration.nix  # Hardware-specific settings (optional)
└── users/
    └── <username>/
        └── home-configuration.nix  # User home-manager config
```

All current hosts (picard, surface, worf, lore, dev) are standard — none use a
`default.nix`; Blueprint automatically discovers them via `configuration.nix` or
`darwin-configuration.nix`. The `mkRpiHost`/`default.nix` pattern this section
used to describe belonged to the RPi fleet, which no longer lives in this repo
(see "Former Raspberry Pi Fleet" above).

### Cachix Integration

The configuration uses these binary caches (`flake.nix` `nixConfig` +
`host-shared.nix` on NixOS/darwin):
- `jdmacd.cachix.org` - Personal cache
- `noctalia.cachix.org` - noctalia (niri shell) packages
- `nix-community.cachix.org` - Community packages

(No `nixos-raspberrypi.cachix.org` or `hyprland.cachix.org` — the RPi fleet
moved to the separate `nix-pi` flake, and this repo now uses niri, not
Hyprland, for its desktop hosts.)

## Key Dependencies

- **blueprint** - Configuration organization framework
- **crann** - Companion library flake of reusable NixOS/home-manager modules (niri,
  noctalia, stylix, vscode, steam, git, kubernetes, shells, terminal); see "crann
  Migration" above
- **nix-darwin** - macOS system management
- **home-manager** - User environment management
- **sops-nix** - Secrets management
- **disko** - Declarative disk partitioning
- **stylix** - System-wide theming (niri is the current desktop compositor, via
  crann — see "crann Migration"; there is no Hyprland flake input in this repo)
- **nur** - Nix User Repository
- **nixos-raspberrypi** - declared as a flake input but currently **unused** in
  `nix/` — a leftover from before the RPi fleet moved to `nix-pi`

## Important Conventions

- All Nix files should be formatted with `nixfmt-rfc-style` and checked with `deadnix`
- Secrets must never be committed unencrypted - always use SOPS
- System state versions are pinned per-host and should not be changed after initial installation
- k3s agent token (picard only) is stored in SOPS and deployed to `/run/secrets/k3s/token`
- Host platform is explicitly set in each configuration (`nixpkgs.hostPlatform`)
- Modules should be imported using `inputs.self.nixosModules.<name>` or `inputs.self.homeModules.<name>` syntax rather than relative paths for consistency
- `networking.hostName` is set in each host's `configuration.nix`, not in `default.nix` helpers

## Test Building
```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel 
```

## Remote Deployment

Deploy to a remote host using:
```bash
nixos-rebuild --use-remote-sudo --target-host <user>@<hostname>.lan --flake .#<hostname> switch
```

Example:
```bash
nixos-rebuild --use-remote-sudo --target-host jmacdonald@picard.lan --flake .#picard switch
```

`worf` is remote-built (`remoteBuild = true` in `flake.nix`'s `deploy.nodes`) and
deployed at `worf.jtec.xyz`, not a `.lan` address.

RPi-specific deployment troubleshooting (boot-partition-full, SD image
generations, etc.) now belongs to the `nix-pi` flake, not this repo.
