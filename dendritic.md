# Dendritic Pattern Analysis for blueprint-personal

This document analyzes the Dendritic Pattern and its compatibility with this Blueprint-based NixOS configuration repository.

## What is the Dendritic Pattern?

The Dendritic Pattern is a design approach for structuring Nix flakes that "flips the configuration matrix" - shifting from a **top-down** (host-centric) to a **bottom-up** (feature-centric) organization.

### Traditional Approach (Top-Down)
```
Host → Services + Apps + Users
  ├── System settings
  ├── Service configuration
  └── User configuration
```

### Dendritic Approach (Bottom-Up)
```
Feature (e.g., "syncthing", "k3s-cluster", "desktop-environment")
  ├── NixOS settings
  ├── Darwin settings
  ├── Home Manager settings
  └── Flake-level boilerplate

Features → Imported by hosts/users as needed
```

### Key Principles

1. **Features are self-contained**: All configuration related to a feature (across NixOS, Darwin, Home Manager) lives in one place
2. **Features are reusable modules**: Defined once, used anywhere
3. **Features compose hierarchically**: Features can import other features using the module system's `imports`
4. **Enabling = Importing**: Instead of `enable = true`, you import the module (which enables things by default)
5. **Cross-platform by design**: A feature defines what it does in multiple contexts (NixOS, Darwin, etc.)

## Technical Foundation

The Dendritic Pattern uses the [flake-parts framework](https://flake.parts), specifically the `flake.modules` attribute to create reusable module libraries.

### Core Mechanism: `flake.modules`

```nix
# Feature module structure
{
  # Define reusable aspects for different module classes
  flake.modules.nixos.myFeature = {
    imports = with inputs.self.modules.nixos; [
      otherFeature
      anotherFeature
    ];

    # NixOS-specific configuration
    services.myservice.enable = true;
  };

  flake.modules.darwin.myFeature = {
    # Darwin-specific configuration
    homebrew.brews = [ "myservice" ];
  };

  flake.modules.homeManager.myFeature = {
    # Home Manager configuration
    programs.myapp.enable = true;
  };

  # Flake-level boilerplate (optional)
  flake.nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
    modules = [ inputs.self.modules.nixos.myFeature ];
  };
}
```

**Important terminology:**
- **Feature**: The overall concept (e.g., "k3s cluster")
- **Aspect**: A feature's configuration for a specific module class (e.g., the NixOS aspect, Darwin aspect)
- **Module class**: The configuration context - `nixos`, `darwin`, `homeManager`, `generic`, etc.

### Enabling flake.modules Support

To use `flake.modules` in a flake-parts project, you must import the modules flake module:

```nix
{
  imports = [
    inputs.flake-parts.flakeModules.modules  # Enables flake.modules attribute
  ];
}
```

Blueprint is built on flake-parts and can support this feature.

## Current State of blueprint-personal

### What We Have ✅

1. **Blueprint framework**: Already using Blueprint (built on flake-parts)
2. **Organized module structure**:
   ```
   nix/modules/
   ├── nixos/     → exposed as nixosModules.<name>
   ├── darwin/    → exposed as darwinModules.<name>
   └── home/      → exposed as homeModules.<name>
   ```
3. **Module wrapping support**: Blueprint supports wrapping modules with `{ flake, inputs, ... }:` for cross-flake references
4. **Modular architecture**: Already organized into reusable modules (ssh, users, k3s-agent, etc.)

### Current Organization Pattern

**Host Configuration** (`nix/hosts/picard/configuration.nix`):
```nix
{
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    inputs.disko.nixosModules.disko
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    k3s-agent-gpu
    docker
    nvidia
    desktop
    greetd
    # ... etc
  ]);

  # Host-specific configuration
  networking.hostName = "picard";
  # ... more config
}
```

**Module Definition** (`nix/modules/nixos/k3s-agent.nix`):
```nix
{ config, pkgs, inputs, perSystem, ... }:
{
  networking.firewall.enable = false;
  # ... k3s configuration
  services.k3s = {
    enable = true;
    package = inputs.self.lib.k3s { inherit pkgs; };
    role = "agent";
    # ... more config
  };
}
```

### What's Different from Dendritic ⚠️

1. **Not using `flake.modules`**: Modules are exposed via Blueprint's automatic discovery, not defined as `flake.modules.<class>.<aspect>`
2. **Host-centric imports**: Hosts import lists of modules rather than being features themselves
3. **No hierarchical feature composition**: Modules don't typically import other modules to build feature hierarchies
4. **Separation of concerns**: Host configuration lives in `hosts/`, module definitions in `modules/`

## Compatibility Assessment

### Is This Project Compatible? ✅ Yes, Largely

**Blueprint already provides the foundation:**
- Built on flake-parts (the framework Dendritic uses)
- Supports module wrapping with `{ flake, inputs, ... }:`
- Organizes modules by type (nixos, darwin, home)
- Blueprint documentation shows `flake.modules` usage (see line 170 of folder_structure.md)

**What would need to change:**
- Enable `flake.modules` support explicitly
- Restructure how features are defined
- Adopt hierarchical module imports
- Convert hosts from configuration files to feature modules

### Benefits of Dendritic Pattern for This Project

1. **Cross-platform Raspberry Pi features**: Define "k3s-cluster" once with aspects for RPi 4, RPi 5, x86_64
2. **Composable host profiles**: "workstation" = desktop + development + personal tools
3. **Self-documenting features**: All k3s config (server, agent, networking, secrets) in one place
4. **Easier external consumption**: Other flakes could import your k3s feature, VPN split-tunnel feature, etc.
5. **Reduced duplication**: Share common patterns across similar hosts (all pi0X hosts)

### Trade-offs

**Pros:**
- Better organization for complex multi-host setups
- Natural abstraction for cross-platform features
- Self-contained, portable features
- Easier to share features between projects

**Cons:**
- Learning curve for the pattern
- More indirection (feature → aspect → module)
- May be overkill for simple single-host configurations
- Requires refactoring existing structure

## How to Adopt the Dendritic Pattern

### Step 1: Enable flake.modules Support

Currently, Blueprint handles module outputs automatically. To use the Dendritic Pattern, you may need to explicitly import flake-parts modules support:

**In your flake.nix or a new feature module:**
```nix
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];
}
```

Verify it works:
```bash
nix eval .#modules.nixos --apply builtins.attrNames
```

### Step 2: Create Feature Modules

Create feature modules that define aspects for different module classes.

**Example: Create `nix/modules/features/k3s-cluster.nix`:**
```nix
{ inputs, ... }:
{
  # Define the k3s-cluster feature aspects
  flake.modules.nixos.k3s-server = {
    imports = with inputs.self.modules.nixos; [
      # Import other required modules
    ];

    # Include content from existing nix/modules/nixos/k3s-server.nix
    services.k3s = {
      enable = true;
      role = "server";
      # ...
    };
  };

  flake.modules.nixos.k3s-agent = {
    imports = with inputs.self.modules.nixos; [
      # Import other required modules
    ];

    # Include content from existing nix/modules/nixos/k3s-agent.nix
    services.k3s = {
      enable = true;
      role = "agent";
      # ...
    };
  };

  # Could also define home-manager aspect for kubectl config, etc.
  flake.modules.homeManager.k3s-tools = {
    home.packages = with pkgs; [
      kubectl
      k9s
    ];
  };
}
```

### Step 3: Convert Hosts to Features

Create host feature modules that compose other features.

**Example: Convert picard to a feature `nix/modules/hosts/picard.nix`:**
```nix
{ inputs, ... }:
{
  # Define picard as a nixos feature/aspect
  flake.modules.nixos.picard = {
    imports = with inputs.self.modules.nixos; [
      # Hierarchically import features
      ssh
      users
      host-shared
      k3s-agent-gpu
      docker
      nvidia
      desktop
      greetd
      eduvpn
      acme
    ];

    # Picard-specific configuration
    networking.hostName = "picard";

    virtualisation.libvirtd = {
      enable = true;
      # ...
    };

    # Include all other picard-specific config
  };

  # Boilerplate to create the actual nixosConfiguration
  flake.nixosConfigurations.picard = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # Import the picard feature
      inputs.self.modules.nixos.picard

      # Add non-feature imports (hardware, external modules)
      ./hosts/picard/hardware-configuration.nix
      ./hosts/picard/disk-configuration.nix
      inputs.disko.nixosModules.disko

      # Set system
      { nixpkgs.hostPlatform = "x86_64-linux"; }
    ];
  };
}
```

### Step 4: Organize Feature Files

The Dendritic Pattern recommends organizing all feature modules in a `modules/` directory. With Blueprint's `nix/` prefix, this becomes `nix/modules/`.

**Recommended structure:**
```
nix/modules/
├── features/           # Cross-cutting features
│   ├── k3s-cluster.nix
│   ├── desktop.nix
│   ├── vpn-split-tunnel.nix
│   └── raspberry-pi.nix
├── hosts/              # Host features
│   ├── picard.nix
│   ├── pi01.nix
│   └── lore.nix
├── users/              # User features
│   └── jmacdonald.nix
└── nixos/              # Existing single-aspect modules (kept for compatibility)
    ├── ssh.nix
    ├── users.nix
    └── ...
```

**Note:** With this structure, you can migrate gradually. Keep existing modules and create new dendritic features alongside them.

### Step 5: Use import-tree for Auto-Loading

The Dendritic Pattern typically uses [vic/import-tree](https://github.com/vic/import-tree) to automatically import all feature modules:

```nix
# In flake.nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix/modules);
```

This auto-imports all `.nix` files in `nix/modules/` as flake-parts modules. Files/folders prefixed with `_` are ignored.

**Blueprint alternative:** Blueprint already auto-discovers modules in `nix/modules/<type>/`. You can continue using this or adopt import-tree for more flexibility.

## Example: Converting k3s-agent Module

### Current Approach

**File:** `nix/modules/nixos/k3s-agent.nix`
```nix
{ config, pkgs, inputs, perSystem, ... }:
{
  networking.firewall.enable = false;
  networking.firewall.checkReversePath = false;
  networking.firewall.allowedTCPPorts = [ 6443 10250 4240 443 80 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];

  sops.secrets."k3s/token" = {
    owner = "root";
  };

  services.k3s = {
    enable = true;
    package = inputs.self.lib.k3s { inherit pkgs; };
    role = "agent";
    tokenFile = "/run/secrets/k3s/token";
    serverAddr = "https://tpi01.lan:6443";
    extraFlags = toString [
      "--node-name ${config.networking.hostName}"
    ];
  };

  fileSystems."/lib/modules" = {
    device = "/run/booted-system/kernel-modules/lib/modules";
    fsType = "none";
    options = [ "bind" ];
  };

  programs.nbd.enable = true;
  environment.systemPackages = with pkgs; [ lvm2 ];
}
```

**Usage in host:**
```nix
# nix/hosts/pi01/configuration.nix
{
  imports = [
    # ...
  ] ++ (with inputs.self.nixosModules; [
    k3s-agent  # Just import the module
    # ...
  ]);
}
```

### Dendritic Approach

**File:** `nix/modules/features/k3s.nix` (feature module)
```nix
{ inputs, ... }:
{
  # Define the k3s-agent aspect
  flake.modules.nixos.k3s-agent = {
    # Hierarchically import dependencies
    imports = with inputs.self.modules.nixos; [
      k3s-common  # Shared k3s configuration
      k3s-networking  # Firewall rules
    ];

    # Agent-specific configuration
    services.k3s = {
      enable = true;
      package = inputs.self.lib.k3s { inherit pkgs; };
      role = "agent";
      tokenFile = config.sops.secrets."k3s/token".path;
      serverAddr = "https://tpi01.lan:6443";
      extraFlags = toString [
        "--node-name ${config.networking.hostName}"
      ];
    };
  };

  # Define the k3s-server aspect
  flake.modules.nixos.k3s-server = {
    imports = with inputs.self.modules.nixos; [
      k3s-common
      k3s-networking
    ];

    services.k3s = {
      enable = true;
      package = inputs.self.lib.k3s { inherit pkgs; };
      role = "server";
      # ... server config
    };
  };

  # Define common k3s configuration aspect
  flake.modules.nixos.k3s-common = {
    sops.secrets."k3s/token".owner = "root";

    fileSystems."/lib/modules" = {
      device = "/run/booted-system/kernel-modules/lib/modules";
      fsType = "none";
      options = [ "bind" ];
    };

    programs.nbd.enable = true;
    environment.systemPackages = with pkgs; [ lvm2 ];
  };

  # Define networking aspect
  flake.modules.nixos.k3s-networking = {
    networking.firewall.enable = false;
    networking.firewall.checkReversePath = false;
    networking.firewall.allowedTCPPorts = [ 6443 10250 4240 443 80 ];
    networking.firewall.allowedUDPPorts = [ 8472 ];
  };

  # Define home-manager aspect for k8s tools
  flake.modules.homeManager.k3s-tools = {
    home.packages = with pkgs; [
      kubectl
      k9s
      helm
      # ...
    ];
  };
}
```

**Usage in host feature:**
```nix
# nix/modules/hosts/pi01.nix
{
  flake.modules.nixos.pi01 = {
    imports = with inputs.self.modules.nixos; [
      k3s-agent  # Now it brings in k3s-common and k3s-networking too
      raspberry-pi-4
      host-shared
    ];

    networking.hostName = "pi01";
    # ... pi01-specific config
  };

  # Boilerplate
  flake.nixosConfigurations.pi01 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ inputs.self.modules.nixos.pi01 ];
  };
}
```

**Key differences:**
1. Feature broken into logical aspects (agent, server, common, networking)
2. Aspects compose via `imports` (agent imports common + networking)
3. All k3s-related config lives in one feature file
4. Can add home-manager aspect for user tools
5. Host imports the feature, which brings in its hierarchy

## Migration Strategy

### Incremental Adoption

You don't need to convert everything at once. Here's a gradual approach:

**Phase 1: Foundation**
1. Verify/enable `flake.modules` support
2. Keep existing structure working
3. Create ONE new feature module (e.g., `vpn-split-tunnel` as it's self-contained)

**Phase 2: Pilot Features**
1. Convert 2-3 features to dendritic style (e.g., k3s, desktop, raspberry-pi)
2. Test with one host using the new pattern
3. Compare ergonomics with old approach

**Phase 3: Host Conversion**
1. Convert one host entirely to a feature module
2. Gradually convert other hosts
3. Keep old modules available for backward compatibility

**Phase 4: Cleanup**
1. Once all hosts use feature modules, optionally clean up old structure
2. Or keep both patterns - they can coexist

### Compatibility Note

Blueprint's automatic module discovery and the Dendritic Pattern can coexist:
- Existing modules in `nix/modules/nixos/` remain accessible as `nixosModules.<name>`
- New feature modules using `flake.modules` are accessible as `modules.nixos.<name>`
- Both can be imported in the same host configuration

## Recommended Next Steps

1. **Study the pattern**: Read the full [Dendritic Basics](https://github.com/mightyiam/dendritic/wiki/Basics) guide
2. **Experiment with a feature**: Create one self-contained feature (e.g., vpn-split-tunnel) in dendritic style
3. **Test external consumption**: Try importing your dendritic feature in another flake
4. **Evaluate benefits**: Decide if the pattern improves your workflow
5. **Choose adoption level**: Partial adoption (some features), full adoption, or stay with current pattern

## References

- [Dendritic Pattern GitHub](https://github.com/mightyiam/dendritic)
- [Dendritic Summary by Vic](https://vic.github.io/dendrix/Dendritic.html)
- [flake-parts Documentation](https://flake.parts)
- [flake-parts modules Option](https://flake.parts/options/flake-parts-modules)
- [Blueprint Documentation](https://numtide.github.io/blueprint/)
- [Blueprint Folder Structure](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)
- [vic/import-tree](https://github.com/vic/import-tree)
- [vic/flake-file](https://github.com/vic/flake-file)

## Conclusion

This Blueprint project is **structurally compatible** with the Dendritic Pattern. The pattern would provide benefits for:
- Complex multi-host configurations (your Raspberry Pi k3s cluster)
- Cross-platform features (NixOS + Darwin with shared home-manager)
- Shareable, reusable features (others could import your k3s or VPN features)

However, adoption requires **reorganization effort**. The current Blueprint structure works well and is easier to understand for traditional NixOS users. The Dendritic Pattern is most valuable when:
- You're building a library of reusable features
- You have many similar hosts that share feature combinations
- You want to publish features for external consumption
- You value the "feature as a unit" mental model

**Recommendation**: Experiment with converting 1-2 self-contained features to the Dendritic style while keeping your existing structure. This lets you evaluate the benefits without committing to a full migration.
