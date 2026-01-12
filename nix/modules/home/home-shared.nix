{
  pkgs,
  osConfig,
  ...
}:
{

  imports = [ ];

  programs = {
    home-manager = {
      enable = true;
    };
  };

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  home.packages =
    with pkgs;
    [ virt-manager ]
    ++ (
      # you can access the host configuration using osConfig.
      pkgs.lib.optionals (osConfig.programs.vim.enable && pkgs.stdenv.isDarwin) [ skhd ]
    );

  home.file = {
    ".local/share/applications/shutdown.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Shutdown
      Comment=Shutdown now
      Exec=bash -c 'sudo shutdown -h now'
      Icon=utilities-terminal
      Terminal=true
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/reboot.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Reboot
      Comment=Reboot now
      Exec=bash -c 'sudo reboot'
      Icon=utilities-terminal
      Terminal=true
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/zellij.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Zellij
      Comment=Open Terminal with Zellij
      Exec=${pkgs.zellij}/bin/zellij attach -c perma-session
      Icon=utilities-terminal
      Terminal=true
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/nixos-packages.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Packages
      Comment=NixOS Packages
      Exec=xdg-open "https://search.nixos.org/packages"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/nixos-options.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Options
      Comment=NixOS Options
      Exec=xdg-open "https://search.nixos.org/options"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/home-manager-options.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Home Manager
      Comment=Home Manager Options
      Exec=xdg-open "https://home-manager-options.extranix.com"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
  };
}
