{ pkgs, inputs, ... }:
let
  theme = "material-vivid";
  moonRise = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jDmacD/wallpapers/refs/heads/main/3840x1600/moon_rise.jpg";
    name = "moon_rise.jpg";
    sha256 = "sha256-0xTBpjInGsSkhjnKNQ6ZYygCGLTsehZb+o1k9mD4sgU=";
  };
in
{

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    image = moonRise;
    targets = { };

    base16Scheme = "${pkgs.base16-schemes}/share/themes/${theme}.yaml";
    polarity = "dark";
    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    opacity = {
      terminal = 0.7;
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };
}
