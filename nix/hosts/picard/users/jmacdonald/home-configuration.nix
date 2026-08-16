{
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}:
{

  imports = [
    inputs.crann.modules.homeManager.git
    inputs.crann.modules.homeManager.kubernetes
    inputs.crann.modules.homeManager.shells
    inputs.crann.modules.homeManager.terminal
  ]
  ++ (with inputs.self.homeModules; [
    home-shared
    personal
    ai-utils
    dev-utils
    nix-utils
    cloud-utils
    network-utils
    sops
    editors
    rpi-utils
    desktop
    # openclaw
  ]);

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

  # programs.noctalia-shell.wallpaper.monitorDirectories = [
  #   {
  #     name = "DP-1";
  #     dimensions = "3840x1600";
  #     wallpaper = "wallhaven-gwweme_3840x1600.png";
  #   }
  # ];

  home.packages = with pkgs; [
    pinta
    upscayl
  ];

  home.stateVersion = "25.11";
}
