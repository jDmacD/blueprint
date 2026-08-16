{
  pkgs,
  config,
  osConfig,
  inputs,
  perSystem,
  ...
}:
{

  imports = [
    inputs.crann.modules.homeManager.git
    inputs.crann.modules.homeManager.kubernetes
    inputs.crann.modules.homeManager.shells
    inputs.crann.modules.homeManager.terminal
    inputs.crann.modules.homeManager.nix-utils
    inputs.crann.modules.homeManager.ai-utils
  ]
  ++ (with inputs.self.homeModules; [
    home-shared
    personal
    dev-utils
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
    nix-utils = {
      enable = true;
      nh = {
        flakePath = "${config.home.homeDirectory}/blueprint";
      };
      extraPackages = [ perSystem.self.cachix-update ];
    };
    ai-utils = {
      enable = true;
      claude-code = {
        enable = true;
        context = ''
          - This is a Linux NixOS Machine
          - Its hostname is picard
          - The local network domain name is .lan
          - The local subnet is 192.168.178.0/24
          - The nix-shell can be used use to access tools for instance
              - `nix-shell --packages ethtool dnsutils --quiet --run "dig +short picard.lan"`
              - `ssh lwh-hotapril.lan 'nix-shell --packages facter --quiet --run "facter -j"'`
          - search for tools and applications with `nh search <application name>`
        '';
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
