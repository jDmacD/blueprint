{
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}:
{

  imports =
    with inputs.self.homeModules;
    [
      home-shared
      personal
      ai-utils
      dev-utils
      nix-utils
      network-utils
      cloud-utils
      sops
      editors
      rpi-utils
      desktop
    ]
    ++ [
      # niri's home config is provided by the crann NixOS module
      # (inputs.crann.modules.nixos.niri) via home-manager.sharedModules;
      # importing the standalone home module here too would double-declare
      # programs.niri.*. Only the standalone (non-NixOS) case imports it.
      inputs.crann.modules.homeManager.git
      inputs.crann.modules.homeManager.kubernetes
      inputs.crann.modules.homeManager.shells
      inputs.crann.modules.homeManager.terminal
    ];

  crann = {
    git.enable = true;
    kubernetes = {
      enable = true;
      extraPackages = [ pkgs.k3d ];
    };
    shells = {
      enable = true;
      flakeInspectPath = "${config.home.homeDirectory}/blueprint";
    };
    terminal = {
      enable = true;
      zellij.extraSettings = {
        web_server_ip = "0.0.0.0";
        web_server_port = 8082;
        web_server_cert = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/cert.pem";
        web_server_key = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/key.pem";
      };
    };
  };

  programs.claude-code.preset = "home";

  # programs.noctalia-shell.wallpaper.monitorDirectories = [
  #   {
  #     name = "eDP-1";
  #     dimensions = "3000x2000";
  #     wallpaper = "wallhaven-n6kwqx_3000x2000.png";
  #   }
  # ];

  home.packages = with pkgs; [
    # blender
    # inkscape
  ];

  home.stateVersion = "24.05";
}
