# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository using [Blueprint](https://github.com/numtide/blueprint) for managing a small set of personal machines: **worf**, **picard**, and **surface**, all actively deployed/critical. A macOS host (**lore**) and a disposable test VM (**dev**) both used to live here too; both were fully decommissioned and removed 2026-08-16 as part of the `blueprint-crann-restructuring` project (see "crann Migration" below) — there is no darwin host or darwin support left in this flake at all. Secrets are managed via SOPS throughout.

The Raspberry Pi fleet (k3s cluster) that this repo originally managed was split out into its own standalone flake, [`nix-pi`](https://github.com/jDmacD/nix-pi) (`~/Code/nix-pi` locally) — it no longer lives here; see "Former Raspberry Pi Fleet" below. **picard** still participates in that cluster as a k3s agent (`k3s-agent-gpu` module), but the cluster's control plane and other nodes are defined in `nix-pi`, not in this repo.

This repo is also mid-migration: reusable modules are being ported out into a companion library flake, [crann](https://github.com/jDmacD/crann), and re-consumed here as a flake input — see "crann Migration" below. Treat this file as a snapshot that can drift from the actual module wiring; when in doubt, grep `nix/hosts/*/configuration.nix` and `nix/hosts/*/users/*/home-configuration.nix` for what a host actually imports rather than trusting this doc's module lists.

## Common Commands

### Building and Deploying

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Switch to new configuration (on target host)
sudo nixos-rebuild switch --flake .
```

(No darwin build/switch commands — there is no darwin host in this repo
anymore; lore was the only one, decommissioned 2026-08-16.)

### Formatting

```bash
# Format all Nix files in the project
nix fmt

# Format specific files/directories
nix fmt nix/hosts/
```

`nix fmt` previously failed with `flake ... does not provide attribute
'formatter.x86_64-linux'` (a pre-existing bug, found 2026-08-16). Root cause
(found 2026-08-16, commit `982fdce`): `flake.nix`'s `inherit (bp) ...` list
never included `formatter`, so blueprint's formatter output
(`nix/formatter.nix`, itself correctly wired) was never re-exported at the
flake's top level — `nix eval .#formatter` misleadingly appeared to work by
falling back to `packages.<system>.formatter` (which blueprint also
populates), but `nix fmt` only ever checks the dedicated top-level
`formatter.<system>` output. Fixed by adding `formatter` to that `inherit`
list.

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
sops nix/secrets/turing.yaml
```

## Architecture

### Blueprint Structure

This repository uses Blueprint with a `nix/` prefix convention:
- `flake.nix` - Main flake configuration with all inputs
- `nix/hosts/` - Per-host configurations
- `nix/modules/nixos/` - NixOS system modules (shared configurations)
- `nix/modules/home/` - home-manager modules (user configurations)
- `nix/lib/` - Shared helper functions (sops, wallpapers) — `stylix.nix` and
  `greetd.nix` were removed 2026-08-16 as dead code (never consumed;
  `greetd.nix` re-exported a nonexistent module, `stylix.nix` was fully
  orphaned once crann's own stylix module took over)
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

`lore` (macOS, nix-darwin + homebrew) and `dev` (disposable/scratch x86_64 Linux
VM, himmelblau module only) both no longer exist in this repo — decommissioned
and fully removed 2026-08-16 as part of the `blueprint-crann-restructuring`
Phase 1 cleanup (commit `276aeb6`): lore's host directory, all
`nix/modules/darwin/*`, the `nix-darwin` flake input, and
`darwinConfigurations`/`darwinModules` wiring are gone entirely, along with
dev's host directory and its only module, `himmelblau.nix`. There is no darwin
support left in this flake at all. `riker` (a former Hyprland workstation)
similarly no longer exists in this repo.

### Former Raspberry Pi Fleet

This repo used to also manage a Raspberry Pi k3s fleet (`pi01`–`pi05`,
`tpi01`–`tpi04`) directly, via `nixos-raspberrypi.lib.nixosSystemFull` and a
`mkRpiHost` helper (`nix/lib/rpi-host.nix`). That fleet has been fully split out
into a standalone flake, [`nix-pi`](https://github.com/jDmacD/nix-pi) — none of
those host directories, the `rpi-host.nix` helper, or the RPi SD-image workflow
exist in this repo anymore. The `nixos-raspberrypi` flake input and the 9 dead RPi `deploy.nodes` entries
that used to sit alongside it (`pi01`–`pi05`, `tpi01`–`tpi04`) were both removed
2026-08-16 (commit `276aeb6`) now that the split is fully done. For actual RPi
fleet docs, see `nix-pi`'s own `CLAUDE.md`.

### Module System

**NixOS Modules** (`nix/modules/nixos/`) — non-exhaustive; see the directory for the
full, fast-moving fleet/service module set (acme, docker, forgejo-runner, github-runner,
k3s-agent-gpu, and similar):
- `host-shared.nix` - Core configuration for all hosts (Nix settings, caching, Stylix)
- `ssh.nix` - SSH server configuration
- `users.nix` - User account management
- `desktop.nix` - GUI host aggregator (peripherals, fonts, gdm, printing) that pulls
  niri/noctalia/stylix/**desktop** (audio, bluetooth, power, gvfs) in from
  **crann** — see "crann Migration" below

`eduvpn.nix`, `vpn-split-tunnel.nix`, and `homebrew.nix` (a darwin-only
module — `system.primaryUser`/`homebrew.*` — that had been misfiled under
`nixos/` and was left orphaned when lore was removed) are all gone —
deleted 2026-08-16, the first two in commit `276aeb6`, `homebrew.nix` in a
follow-up cleanup pass (commit `bc3937e`) once it was flagged. There is no
VPN split-tunneling NixOS module in this repo anymore (see "VPN Split
Tunneling" below).

**home-manager Modules** (`nix/modules/home/`):
- `home-shared.nix` - Base home configuration (devbox, pre-commit, sops, ssh-agent)
- `firefox.nix` - Firefox browser setup
- `personal.nix` - Personal development tools + git identity
- `desktop.nix` - Desktop aggregator that pulls noctalia/vscode/wl-clipboard in
  from **crann**

`terminals.nix`/`terminal-utils.nix` (superseded by crann's `terminal`),
`kubernetes-utils.nix` (superseded by crann's `kubernetes`), `git-utils.nix`
(superseded by crann's `git`), `work.nix` (unused by any host), and
`ai-utils.nix`/`nix-utils.nix` (superseded by crann's own modules, picard was
their last consumer) were all deleted 2026-08-16 across the
`blueprint-crann-restructuring` project's Phases 1 and 5 (commits `276aeb6`,
`5b45843`) — every host is now on crann's equivalents.

There are no **darwin Modules** anymore — `nix/modules/darwin/` (`host-shared.nix`,
`sops.nix`, `stylix.nix`) was deleted in full 2026-08-16 when lore, the only
darwin host, was decommissioned.

### crann Migration

Reusable modules are being ported out of this repo and into
[crann](https://github.com/jDmacD/crann) (`~/Code/crann` locally), a separate
flake-parts/dendritic library flake, then re-imported here via the `crann` flake
input (`inputs.crann.modules.<class>.<name>`). See crann's own `CLAUDE.md` for its
conventions.

**A dedicated `blueprint-crann-restructuring` project (5 phases, commits
`276aeb6`..`5b45843`, 2026-08-16) finished the bulk of this migration**:
cleanup of dead/broken code left from the RPi split, full lore/dev
decommission, standardizing enablement on inline (no per-host wrapper files),
worf's and picard's remaining local-vs-crann gaps, and the nixos/home
`desktop.nix` dedup are all done. What's left is deliberately out of scope
(documented, not overlooked — see below), not an oversight. Still true going
forward: **migration state can drift again** — check each host's
`configuration.nix`/`home-configuration.nix` for its actual
`inputs.crann.modules.*` imports rather than trusting this summary as it ages.
Per-host state as of 2026-08-16:

- **picard** (NixOS + home): `desktop` module pulls in crann's `niri`/
  `noctalia`/`stylix`/**`desktop`** (audio, bluetooth, power, gvfs) at the
  NixOS level; `crann.steam` (NixOS, picard-only, inline); home-manager:
  `git`, `kubernetes`, `shells`, `terminal`, `nix-utils`, and now **`ai-utils`**
  too (migrated off the local module in Phase 5 — see the known gap below).
- **surface** (NixOS + home): same NixOS-level `desktop` module
  (niri/noctalia/stylix/desktop); enabled inline
  (`crann.optnix.enable = true` directly in `configuration.nix` — the old
  per-host `nix/modules/nixos/crann.nix` wrapper file is gone, collapsed back
  to inline in Phase 2 to match picard's style fleet-wide); home-manager:
  `git`, `kubernetes`, `shells`, `terminal`, `nix-utils`, `optnix`, `obsidian`,
  `ai-utils`. Still the only host on `crann.obsidian` — deliberately not yet
  extended to picard (crann's newest, least battle-tested module; no fixed
  date to change that).
- **worf** (NixOS + home, headless — no desktop stack at all): home-manager:
  `shells`, `terminal`, and now **`nix-utils`** too (Phase 3). No
  `git`/`kubernetes`/niri/noctalia/stylix/vscode/ai-utils on worf — not needed
  on a headless VPS.
- **lore** (darwin): fully decommissioned and removed from this repo
  2026-08-16 — see "Host Types and Naming" above. No darwin support remains
  in this flake at all.

**Known, deliberately accepted gap (picard, since 2026-08-16 Phase 5):**
crann's `ai-utils` module only covers `claude-code`/`claude-obsidian`; it has
no equivalent for what picard's old local `ai-utils.nix` also used to provide
— `programs.aichat` (an Ollama client config), preset-based MCP servers
(steampipe/argocd/grafana/gitlab, wired via `sops.secrets.mcp_env`), and the
`kagent` package. These were dropped from picard by the migration rather than
kept as a local supplement — an explicit call, not an oversight — pending
that MCP tooling eventually being ported into crann itself.

picard's Sunshine/Hyprland game-streaming setup (`sunshine.nix`) is staying
local — porting it raises a separate Hyprland-in-crann design question; its
dedicated-user session module (`hyprland-sunshine.nix`) was removed separately
when Sunshine's dedicated user was retired (commit `370514a`, unrelated to
this migration).

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
- `nix/secrets/turing.yaml` - Turing Pi / RPi-fleet-adjacent secrets (personal key)
- `nix/hosts/secrets.yaml` - Shared host secrets (all host keys)
- `nix/hosts/<hostname>/secrets.yaml` - Per-host secrets

Age keys are defined in `.sops.yaml`. It still lists keys for the former RPi fleet
hosts (`pi01`–`pi05`, `tpi01`–`tpi04`, `uconsole`) — stale leftovers from before
the `nix-pi` split, not evidence those hosts are still managed here — alongside
the currently-relevant `hel-1`, `picard`, `surface`, `worf`. `lore`'s key was
fully removed (`sops updatekeys` re-encrypted `nix/hosts/secrets.yaml` to drop
it as a recipient) when lore itself was decommissioned 2026-08-16.

### VPN Split Tunneling (removed 2026-08-16)

This repo used to provide automatic VPN split tunneling: a NixOS module
(`nix/modules/nixos/vpn-split-tunnel.nix`, exposing
`networking.vpnSplitTunnel.enable`) plus a NetworkManager dispatcher script
package (`nix/packages/vpn-split-tunnel/`) it wired in. It detected EduVPN
connections, kept the VPN off the default route, split DNS so local `.lan`
queries stayed on the local resolver, and deleted conflicting routes for
local network ranges, so work-VPN and local (`.lan`/k3s) resources stayed
simultaneously reachable. Both the module (zero-referenced, commit
`276aeb6`) and the now-orphaned package (commit `bc3937e`) have been fully
deleted — there is no VPN split-tunneling functionality left in this repo
at all.

### Host Configuration Pattern

Each host follows this structure:
```
nix/hosts/<hostname>/
├── configuration.nix        # Main system config
├── hardware-configuration.nix  # Hardware-specific settings (optional)
└── users/
    └── <username>/
        └── home-configuration.nix  # User home-manager config
```

All current hosts (picard, surface, worf) are standard — none use a
`default.nix`; Blueprint automatically discovers them via `configuration.nix`.
(There is no `darwin-configuration.nix` host anywhere in this repo anymore —
lore, the only darwin host, was fully decommissioned 2026-08-16.) The
`mkRpiHost`/`default.nix` pattern this section used to describe belonged to
the RPi fleet, which no longer lives in this repo (see "Former Raspberry Pi
Fleet" above).

### Cachix Integration

The configuration uses these binary caches (`flake.nix` `nixConfig` +
`host-shared.nix` on NixOS):
- `jdmacd.cachix.org` - Personal cache
- `noctalia.cachix.org` - noctalia (niri shell) packages
- `nix-community.cachix.org` - Community packages

(No `nixos-raspberrypi.cachix.org` or `hyprland.cachix.org` — the RPi fleet
moved to the separate `nix-pi` flake, and this repo now uses niri, not
Hyprland, for its desktop hosts.)

## Key Dependencies

- **blueprint** - Configuration organization framework
- **crann** - Companion library flake of reusable NixOS/home-manager modules (niri,
  noctalia, stylix, desktop, vscode, steam, git, kubernetes, shells, terminal,
  nix-utils, ai-utils, optnix, obsidian); see "crann Migration" above
- **home-manager** - User environment management
- **sops-nix** - Secrets management
- **disko** - Declarative disk partitioning
- **stylix** - System-wide theming, consumed only via crann's own `stylix`
  module (`inputs.crann.modules.nixos.stylix`) — blueprint's own direct
  `stylix` flake input was removed 2026-08-16 as unused (niri is the current
  desktop compositor; there is no Hyprland flake input in this repo)
- **nur** - Nix User Repository

(`nix-darwin` and `nixos-raspberrypi` were both removed as flake inputs
2026-08-16, along with `attic`, `noctalia`, `devshell`, `treefmt-nix`, and
`himmelblau` — all confirmed zero-referenced. `deploy-rs` and `nur` were kept:
both are genuinely used, `deploy-rs` directly in `flake.nix`'s deploy helper
and `nur` via `perSystem.nur.repos.rycee.firefox-addons` in `home/firefox.nix`.)

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
