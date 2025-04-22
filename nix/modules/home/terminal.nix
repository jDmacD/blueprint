{ pkgs, osConfig, ... }:
{

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.alacritty = {
    enable = true;
  };
  programs.foot = {
    enable = true;
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
