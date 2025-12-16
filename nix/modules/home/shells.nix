{ pkgs, config, ... }:
{

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      update-darwin = "sudo nix run nix-darwin -- switch --flake ~/blueprint/";
      ls = "eza";
      cd = "z";
    };
    history.size = 10000;
  };

}
