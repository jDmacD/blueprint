{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # https://docs.noctalia.dev/getting-started/nixos/#config-ref
      bar = {
        backgroundOpacity = lib.mkDefault 0.0;
        useSeparateOpacity = true;
      };
      location = {
        name = "Kilkenny";
      };
      general = {
        radiusRatio = 0;
        iRadiusRatio = 0;
        boxRadiusRatio = 0;
        screenRadiusRatio = 0;
      };
      ui = {
        panelsAttachedToBar = false;
      };
      appLauncher = {
        terminalCommand = "foot";
      };
    };
  };
}
