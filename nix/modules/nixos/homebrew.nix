{ pkgs, ... }:
{

  system.primaryUser = "jmacdonald";
  homebrew.enable = true;
  homebrew.brews = [
  ];
  homebrew.casks = [
    "ghostty"
    "nikitabobko/tap/aerospace"
    "docker-desktop"
  ];

}
