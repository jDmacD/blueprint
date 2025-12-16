{ pkgs }:
{
  enable = true;
  autoEnable = true;
  image = pkgs.fetchurl {
    url = "https://github.com/jDmacD/wallpapers/blob/main/3440x1440/simon_stalenhag/AknbEel.jpeg?raw=true";
    sha256 = "sha256-fieTqLhftyXiOfWE39K81xqQUcW47yUOeci2INlCOWU=";
  };
  targets = { };
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
}
