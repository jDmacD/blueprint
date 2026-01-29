# Headless Hyprland Setup for Sunshine Streaming

## Goal

Configure picard host to automatically start a Hyprland session on boot without a display manager (GDM) for use with Sunshine game streaming. This allows remote streaming without requiring physical login or monitor attachment.

## Approach Taken

### 1. Created Custom Modules

**`nix/modules/nixos/hyprland-headless.nix`**
- Enables autologin to TTY1 for specified user
- Configures UWSM (Universal Wayland Session Manager) with Hyprland compositor
- Creates systemd user service to start Hyprland via `uwsm start`
- Sets proper environment variables (XDG_RUNTIME_DIR, XDG_DATA_DIRS)

**`nix/modules/nixos/desktop-headless.nix`**
- Copy of desktop.nix without GDM
- Includes Hyprland, Stylix, fonts, and other desktop components
- Suitable for headless setups that need desktop environment features

### 2. Configuration Changes

**picard host configuration**
- Replaced `desktop` module with `desktop-headless`
- Added `hyprland-headless` module
- Configured to run as user `jmacdonald`

**Sunshine module**
- Uncommented headless output creation in prep-cmd:
  ```nix
  {
    do = "${hyprctl} output create headless SUNSHINE-1";
    undo = "${hyprctl} output remove SUNSHINE-1";
  }
  ```

**Hyprland home-manager config**
- Added fallback monitor configuration to handle unknown/virtual displays:
  ```nix
  monitor = [
    ",preferred,auto,1"  # Fallback for unknown monitors
  ];
  ```

### 3. Troubleshooting Steps

#### Issue 1: UWSM couldn't find hyprland executable
**Error:** `"hyprland" not found or is not executable!`

**Solutions tried:**
- Added `programs.uwsm.waylandCompositors.hyprland` configuration
- Set `binPath = "${pkgs.hyprland}/bin/start-hyprland"`
- Added `XDG_DATA_DIRS` environment variable to service
- Changed from `uwsm start hyprland` to full path: `uwsm start ${pkgs.hyprland}/bin/Hyprland`

#### Issue 2: XDG_RUNTIME_DIR not expanded
**Error:** `[Errno 2] No such file or directory: '/run/user/$(id -u)/systemd/user'`

**Solution:** Changed from `$(id -u)` to systemd specifier `%U`

#### Issue 3: systemd service type mismatch
**Error:** `Failed with result 'protocol'`

**Solution:** Changed service type from `Type=notify` to `Type=simple` since uwsm doesn't send systemd notifications

#### Issue 4: Hyprland backend initialization failure
**Error:** `terminate called after throwing an instance of 'std::runtime_error' what(): CBackend::create() failed!`

**Root cause:** Hyprland cannot initialize without at least one DRM output (display). With no physical monitor connected and `Disp.A = Off` in nvidia-smi, the GPU has no outputs available for Hyprland to use.

**Environment variables tried:**
- `WLR_BACKENDS = "headless"` - Did not work with Hyprland 0.53.1
- `WLR_LIBINPUT_NO_DEVICES = "1"` - Did not resolve backend issue
- `WLR_RENDERER_ALLOW_SOFTWARE = "1"` - Did not resolve backend issue

## Current Status

- Systemd service starts successfully
- UWSM launches Hyprland
- Hyprland crashes after ~6 seconds with backend initialization failure
- Service exits with status 0 but Hyprland process terminates abnormally

**System details:**
- Host: picard
- GPU: NVIDIA GeForce RTX 2060 (TU106)
- Driver: nvidia 590.48.01
- Hyprland: 0.53.1
- NVIDIA DRM modesetting: enabled
- Physical display connected: No

## Proposed Solutions

### Option A: HDMI Dummy Plug (Recommended)

**Description:** Use a hardware HDMI dummy plug to simulate a connected display.

**How it works:**
- Plug HDMI dummy adapter into NVIDIA GPU
- GPU detects it as a real display and creates DRM output
- Hyprland can initialize with this "display"
- Sunshine can create additional virtual displays as needed

**Pros:**
- Most reliable solution for headless streaming
- Widely used in similar setups
- Works with any compositor
- No software workarounds needed

**Cons:**
- Requires hardware purchase (~$10-20)
- Physical access to machine needed for installation

**Products:**
- Search for "HDMI dummy plug" or "HDMI ghost display adapter"
- Common resolutions: 1920x1080, 3840x2160
- Make sure it supports your desired streaming resolution

### Option B: Connect Physical Monitor

**Description:** Connect the LG 38GN950 monitor that's configured in the Hyprland config.

**How it works:**
- Physical monitor provides real DRM output
- Hyprland starts normally
- Can still stream via Sunshine while monitor is connected

**Pros:**
- No additional hardware needed
- Immediate solution
- Can see what's happening on physical display

**Cons:**
- Requires monitor to remain connected
- Uses physical space and power
- Defeats purpose of "headless" setup

### Option C: X11 with Xvfb

**Description:** Switch from Wayland/Hyprland to X11 with virtual framebuffer.

**How it works:**
- Use Xvfb (X virtual framebuffer) to create virtual X11 display
- Run X11 window manager (i3, openbox, etc.)
- Sunshine captures X11 session

**Configuration approach:**
```nix
# Create systemd service for Xvfb
systemd.services.xvfb = {
  script = "Xvfb :1 -screen 0 1920x1080x24";
};

# Start window manager on virtual display
systemd.services.window-manager = {
  environment.DISPLAY = ":1";
  script = "i3";
};
```

**Pros:**
- Proven solution for headless scenarios
- Xvfb designed for virtual displays
- Well-documented

**Cons:**
- Loses Wayland benefits
- Different compositor/WM needed
- More configuration changes required
- X11 is legacy technology

### Option D: Different Wayland Compositor

**Description:** Replace Hyprland with a compositor that handles headless better.

**Candidates:**
- **cage**: Kiosk-style compositor, minimal
- **weston**: Reference Wayland compositor, has headless backend
- **sway**: i3-like tiling compositor with better headless support

**Example with weston:**
```nix
services.weston-headless = {
  enable = true;
  backend = "headless";
  width = 1920;
  height = 1080;
};
```

**Pros:**
- Stays on Wayland
- Some compositors designed for headless
- May work without hardware changes

**Cons:**
- Different compositor means different config/workflow
- May have different feature set than Hyprland
- Still may require virtual outputs
- Less documentation for headless gaming scenarios

### Option E: Hybrid Approach

**Description:** Keep GDM for optional physical access, add autologin, configure for both use cases.

**How it works:**
- Restore GDM (graphical login)
- Enable autologin for headless user
- Hyprland starts automatically but GDM remains available
- Can switch to different TTY for manual login if needed

**Pros:**
- Flexibility for both headless and physical use
- Can still login normally when needed
- Easier troubleshooting

**Cons:**
- Still requires display output (dummy plug or real monitor)
- More complex configuration
- GDM overhead

## Recommendations

**For dedicated streaming server (most common use case):**
→ **Option A: HDMI Dummy Plug**

This is the standard solution used by the game streaming community. It's reliable, works with any compositor, and allows full Wayland/Hyprland functionality without workarounds.

**For dual-purpose workstation:**
→ **Option E: Hybrid Approach** with dummy plug

Keeps flexibility to use the machine normally while still supporting headless streaming.

**If no hardware purchase is possible:**
→ **Option C: X11 with Xvfb**

Most reliable software-only solution, though it means moving away from Wayland.

## Files Modified

- `nix/modules/nixos/hyprland-headless.nix` (created)
- `nix/modules/nixos/desktop-headless.nix` (created)
- `nix/modules/nixos/sunshine.nix` (modified)
- `nix/modules/home/hyprland.nix` (modified)
- `nix/hosts/picard/configuration.nix` (modified)

## References

- [UWSM Documentation](https://github.com/Vladimir-csp/uwsm)
- [Hyprland Wiki - Headless](https://wiki.hyprland.org/Configuring/Monitors/#headless)
- [Sunshine Documentation](https://docs.lizardbyte.dev/projects/sunshine/en/latest/)
- [Reddit: Headless gaming setups](https://www.reddit.com/r/cloudygamer/)

## Next Steps

1. Decide on approach (recommend Option A)
2. If using dummy plug:
   - Order HDMI dummy plug
   - Install and reboot
   - Verify Hyprland starts: `systemctl --user status hyprland-headless`
   - Test Sunshine streaming
   - Create headless outputs: `hyprctl output create headless SUNSHINE-1`
3. If using different approach, see specific configuration above
