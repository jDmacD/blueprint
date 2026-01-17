{ pkgs, inputs }:
let
  theme = "material-vivid";
in
{
  enable = true;
  autoEnable = true;
  image = (import inputs.self.lib.wallpapers { inherit pkgs; }).moonRise;
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
}
