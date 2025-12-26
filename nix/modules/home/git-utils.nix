{ pkgs, ... }:
{

  home.packages = with pkgs; [
    pre-commit
  ];
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
  };
}
