{ pkgs, osConfig, ... }:
{

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
  programs.claude-code = {
    enable = true;
  };
  programs.nh = {
    enable = true;
    darwinFlake = "/Users/jmacdonald/blueprint";
  };
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
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
    };
    history.size = 10000;
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
  programs.alacritty = {
    enable = true;
  };
  programs.foot = {
    enable = pkgs.stdenv.isLinux;
    package = pkgs.foot;
    settings = {
      main = {
        term = "xterm-256color";
      };
    };
  };
  programs.kitty = {
    enable = true;
    settings = {
      disable_ligatures = "cursor";
      cursor_shape = "block";
      scrollback_lines = 10000;
      mouse_hide_wait = 0;
      detect_urls = "yes";
      show_hyperlink_targets = "yes";
      url_style = "straight";
      strip_trailing_spaces = "smart";
      focus_follows_mouse = "no";
      enable_audio_bell = "no";
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_switch_strategy = "previous";
      dynamic_background_opacity = "yes";
      update_check_interval = 0;
      allow_hyperlinks = "yes";
    };
  };

  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false;
  };

}
