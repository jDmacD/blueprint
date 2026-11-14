# One Noctalia desktop for every host, with per-host overrides.
#
# Noctalia merges every ~/.config/noctalia/*.toml in alphabetical order (tables
# merge key by key, a list replaces the earlier list), then the GUI's
# ~/.local/state/noctalia/settings.toml on top. This module uses that instead of
# merging attrsets in Nix:
#
#   config.toml   crann.noctalia / stylix (theme, palette, font)  programs.noctalia.settings
#   desktop.toml  the shared desktop, captured from the GUI       ./desktop.toml in this repo
#   host.toml     this host's outputs, folders, devices           crann.noctalia.hostSettings
#   settings.toml live GUI tweaks until they're captured          Noctalia
#
# `noctalia-capture` diffs the GUI layer against the declared files and writes
# the host-independent part into desktop.toml; see capture.py.
#
# Written against crann's option names (crann.noctalia.*) so it can move into
# crann's modules/home/noctalia.nix as-is.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.crann.noctalia;
  tomlFormat = pkgs.formats.toml { };
  noctalia = config.programs.noctalia.package;

  # Same check the upstream module runs on config.toml.
  validated =
    name: src:
    pkgs.runCommand "noctalia-${name}" { } ''
      ${lib.getExe noctalia} config validate ${src}
      cp ${src} $out
    '';

  capture = pkgs.writeShellApplication {
    name = "noctalia-capture";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      export NOCTALIA_BIN=${lib.getExe noctalia}
      export REMARSHAL_BIN=${lib.getExe' pkgs.remarshal "remarshal"}
      exec python3 -I ${./capture.py} "$@"
    '';
  };
in
{
  options.crann.noctalia = {
    desktop = {
      enable = lib.mkEnableOption "the shared Noctalia desktop (desktop.toml + host.toml layers)";

      settingsFile = lib.mkOption {
        type = lib.types.path;
        default = ./desktop.toml;
        description = ''
          The shared desktop layer, installed as ~/.config/noctalia/desktop.toml.
          Fill it with `noctalia-capture --write <checkout>/…/desktop.toml`.
        '';
      };
    };

    hostSettings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        This host's layer, installed as ~/.config/noctalia/host.toml and merged
        over desktop.toml: per-monitor wallpaper folders and bars (match outputs
        by description substring, e.g. "P2419H", not by connector), devices,
        and any plugin setting that has to differ on this host.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    xdg.configFile = {
      "noctalia/desktop.toml".source = validated "desktop.toml" cfg.desktop.settingsFile;
      "noctalia/host.toml" = lib.mkIf (cfg.hostSettings != { }) {
        source = validated "host.toml" (tomlFormat.generate "host.toml" cfg.hostSettings);
      };
    };

    home.packages = [ capture ];
  };
}
