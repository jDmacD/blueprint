{ pkgs }:
{

  theBurgerBox = pkgs.fetchurl {
    url = "https://github.com/jDmacD/wallpapers/blob/main/3440x1440/simon_stalenhag/AknbEel.jpeg?raw=true";
    name = "AknbEel.jpeg";
    sha256 = "sha256-fieTqLhftyXiOfWE39K81xqQUcW47yUOeci2INlCOWU=";
  };

  lookToWindward = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jDmacD/wallpapers/refs/heads/main/3840x1600/mark_salwowski/look_to_windward.png";
    name = "look_to_windward.png";
    sha256 = "sha256-fieTqLhftyXiOfWE39K81xqQUcW47yUOeci2INlCOWU=";
  };
}
