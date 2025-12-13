{ pkgs, ... }:
{

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
    dejavu_fonts
    noto-fonts-color-emoji
  ];

}
