{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.niri
  ];
  programs.niri = {
    enable = true;
    settings = {
      # https://github.com/sodiboo/niri-flake/blob/main/docs.md#programsnirisettings
      # For vscode etal
      environment = {
        "NIXOS_OZONE_WL" = "1";
      };
      # https://docs.noctalia.dev/getting-started/compositor-settings/niri/
      window-rules = [
        {
          geometry-corner-radius = {
            bottom-left = 20.0;
            bottom-right = 20.0;
            top-left = 20.0;
            top-right = 20.0;
          };
        }
        { clip-to-geometry = true; }
      ];
      debug = {
        honor-xdg-activation-with-invalid-serial = [ ];
      };
      spawn-at-startup = [
        {
          command = [
            "noctalia-shell"
          ];
        }
      ];
    };
  };
}
