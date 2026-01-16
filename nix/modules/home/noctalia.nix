{
  inputs,
  pkgs,
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
    };
  };
}
