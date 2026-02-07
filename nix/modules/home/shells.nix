{ pkgs, config, ... }:
{

  programs.zsh = {
    enable = true;
    enableCompletion = false; # Disabled to avoid nix-zsh-completions conflict with nixos-rebuild-ng
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      update-darwin = "sudo nix run nix-darwin -- switch --flake ~/blueprint/";
      ls = "eza";
      cd = "z";
      blueprint-inspect = "${pkgs.nix-inspect}/bin/nix-inspect --expr 'builtins.getFlake \"${config.home.homeDirectory}/blueprint\"'";
    };
    history.size = 10000;
    initContent = ''
      # Manually enable completions without nix-zsh-completions
      autoload -U compinit && compinit
    '';
  };

}
