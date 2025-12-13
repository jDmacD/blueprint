{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    devbox
    jq
    yq-go
  ];
  programs.claude-code = {
    enable = true;
  };
  programs.nh = {
    enable = true;
    darwinFlake = "/Users/jmacdonald/blueprint";
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };
  programs.btop = {
    enable = true;
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      update = "sudo nix run nix-darwin -- switch --flake ~/blueprint/";
      ls = "eza";
      cd = "z";
    };
    history.size = 10000;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      kubernetes = {
        disabled = false;
      };
      localip = {
        ssh_only = false;
        disabled = false;
      };
      status = {
        disabled = false;
      };
    };
  };
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false;
  };

}
