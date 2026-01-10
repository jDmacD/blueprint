# Himmelblau Azure AD Authentication Troubleshooting

## Overview

This document details the troubleshooting process for setting up Azure AD authentication via Himmelblau on NixOS.

## Issues Encountered and Solutions

### 1. Group Authorization Failure (CRITICAL - RESOLVED)

**Symptom:**
```
DEBUG: Checking if user is in allowed groups ({"55f3aff4-8f5f-4aab-bdde-3cebfdb018a8 ae84f46e-7ea6-4394-a9f2-8d82c0dea98a"})
DEBUG: Number of intersecting groups: 0
ERROR: could not obtain user info (jmacdonald@jtec.xyz)
ERROR: Authentication service cannot retrieve authentication info
```

**Root Cause:**

The NixOS himmelblau module converts Nix lists to **space-separated strings** in the INI config file:
```nix
pam_allow_groups = [
  "55f3aff4-8f5f-4aab-bdde-3cebfdb018a8"
  "ae84f46e-7ea6-4394-a9f2-8d82c0dea98a"
]
# Generates: pam_allow_groups = 55f3aff4-... ae84f46e-...
```

However, himmelblau expects **comma-separated** group IDs according to its documentation. When space-separated, himmelblau treats the entire string as a single group ID, causing 0 group intersections even when the user is in the correct groups.

**Solution:**

Pass `pam_allow_groups` as a **comma-separated string** instead of a Nix list:
```nix
pam_allow_groups = ["55f3aff4-8f5f-4aab-bdde-3cebfdb018a8,ae84f46e-7ea6-4394-a9f2-8d82c0dea98a"];
```

**Verification:**
After fix: `Number of intersecting groups: 2` ✓

**Note:** This appears to be a mismatch between the NixOS module's INI generation (`mkValueString` uses space separator for lists) and what himmelblau expects. This may warrant a GitHub issue or PR to the himmelblau-idm/himmelblau repository.

### 2. Home Directory Path Mismatch (RESOLVED)

**Symptom:**
- NSS returns home directory: `/home/jmacdonald@jtec.xyz`
- Actual pre-existing directory: `/home/jmacdonald` (local user, uid=1000)
- Azure AD user uid: 5081030

**Root Cause:**

By default, himmelblau uses:
- `home_attr = "UUID"` - Uses Azure AD UUID for home directory base name
- `home_alias = "SPN"` - Uses Service Principal Name (email) for symlink alias

This creates:
- Physical directory: `/home/<uuid>` (e.g., `/home/6625e88e-85fd-4c5a-88ea-090fd84890cd`)
- Symlink: `/home/jmacdonald@jtec.xyz` → `/home/<uuid>`

**Solution for Coexistence:**

To allow both local users and Azure AD users with the same base username:

1. Keep default `home_attr` and `home_alias` settings (don't override)
2. Azure AD users get `/home/username@domain.com`
3. Local users keep `/home/username`

**Alternative: Shared Home Directory**

If you want Azure AD and local users to share the same home directory:
```nix
home_attr = "CN";   # Common Name (short username)
home_alias = "CN";  # Use CN for both directory and alias
```

This creates `/home/jmacdonald` for both, but requires:
- Static UID mapping (map Azure AD user to same UID as local user)
- Removing local user, OR
- Ensuring ownership matches Azure AD user UID

**Current Configuration:**

We chose coexistence mode (default settings) to keep both users separate.

### 3. Home Directory Ownership Issues

**Symptom:**
```
Failed to open /home/jmacdonald/.config/systemd/user.conf: Permission denied
systemd[...]: Failed to allocate manager object: Permission denied
```

**Root Cause:**

When himmelblau creates the home directory (`/home/<uuid>`), it initially creates it with incorrect ownership (local user uid=1000 instead of Azure AD user uid=5081030).

**Solution:**

Manually fix ownership after first login attempt:
```bash
# Find the UUID-based home directory
ls -la /home/ | grep -E "<azure-uuid>"

# Fix ownership
sudo chown -R <azure-uid>:<azure-gid> /home/<uuid>

# Example:
sudo chown -R 5081030:5081030 /home/6625e88e-85fd-4c5a-88ea-090fd84890cd
```

**Verification:**
```bash
stat -c "%U %u:%g" /home/<uuid>
# Should show: username <azure-uid>:<azure-gid>
```

### 4. Systemd User Session Permission Issues (ONGOING)

**Symptom:**
After fixing ownership, systemd still reports:
```
systemd[...]: Failed to allocate manager object: Permission denied
```

**Status:** UNRESOLVED

**Possible Causes:**
1. PAM systemd module configuration issues
2. XDG_RUNTIME_DIR permissions/creation
3. systemd-logind integration with himmelblau
4. SELinux/AppArmor policies (unlikely on NixOS default)

**Areas to Investigate:**
- Check if `/run/user/<azure-uid>` is created correctly
- Verify PAM configuration includes `pam_systemd.so` properly
- Review systemd-logind logs during login
- Check if user is properly added to systemd-relevant groups

## Configuration Reference

### Working Configuration (nix/modules/nixos/himmelblau.nix)

```nix
services.himmelblau = {
  enable = true;
  pamServices = [
    "passwd"
    "login"
    "systemd-user"
  ];
  settings = {
    domain = "jtec.xyz";
    apply_policy = false;
    hello_pin_min_length = 4;

    # CRITICAL: Use comma-separated string, not Nix list
    pam_allow_groups = ["guid1,guid2,guid3"];

    # For coexistence with local users (default settings)
    # home_attr defaults to "UUID"
    # home_alias defaults to "SPN"
    # Creates /home/username@domain.com → /home/<uuid>

    # For shared home directories (uncomment if needed):
    # home_attr = "CN";
    # home_alias = "CN";

    local_groups = [
      "wheel"
      "docker"
    ];
  };
};
```

### Verification Commands

```bash
# Check NSS resolution
sudo getent passwd username@domain.com

# Check group intersection (should be > 0)
sudo journalctl -u himmelblaud.service | grep "intersecting groups"

# Check home directory ownership
ls -ld /home/username@domain.com
stat -c "%u:%g" /home/username@domain.com

# Test authentication (without full login)
sudo aad-tool auth-test --name username@domain.com

# Clear himmelblau cache after config changes
sudo aad-tool cache-clear

# Restart services after config changes
sudo systemctl restart himmelblaud.service himmelblaud-tasks.service
```

## Key Lessons

1. **Always use comma-separated strings for `pam_allow_groups`** - The NixOS module's list-to-space-separated conversion doesn't match what himmelblau expects

2. **Home directory strategy matters** - Decide upfront whether Azure AD and local users will share home directories or be kept separate

3. **Cache invalidation is critical** - After configuration changes, always run `sudo aad-tool cache-clear` before testing

4. **Service restarts required** - Configuration file changes don't automatically reload; services must be restarted

5. **NSS debugging** - Use `getent passwd username@domain.com` to verify NSS resolution before attempting login

## References

- Himmelblau GitHub: https://github.com/himmelblau-idm/himmelblau
- Himmelblau Documentation: Configuration expects comma-separated group IDs
- NixOS Module Source: `flake.nix` in himmelblau repository

## Potential Upstream Issues

1. **NixOS module INI generation**: The `mkValueString` function converts lists to space-separated values, but himmelblau expects commas for `pam_allow_groups`

2. **Home directory ownership**: The `himmelblaud-tasks` service may be creating home directories with incorrect initial ownership

Consider filing GitHub issues at https://github.com/himmelblau-idm/himmelblau/issues
