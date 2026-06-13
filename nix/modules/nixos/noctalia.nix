{ pkgs, inputs, ... }:
{
  # Running noctalia-shell as a systemd service is deprecated upstream; instead the
  # shell is launched from the compositor (see home/hyprland.nix exec-once and
  # home/niri.nix spawn-at-startup). Just make the package available system-wide.
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
