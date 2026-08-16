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
      dev-utils
      network-utils
      cloud-utils
      sops
      editors
      rpi-utils
      desktop
    ]
    ++ (with inputs.crann.modules.homeManager; [
      # niri's home config is provided by the crann NixOS module
      # (inputs.crann.modules.nixos.niri) via home-manager.sharedModules;
      # importing the standalone home module here too would double-declare
      # programs.niri.*. Only the standalone (non-NixOS) case imports it.
      git
      kubernetes
      shells
      terminal
      nix-utils
      optnix
      obsidian
      ai-utils
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
    };
    optnix = {
      enable = true;
    };
    obsidian = {
      enable = true;
    };
    ai-utils = {
      enable = true;
      claude-code = {
        enable = true;
        context = ''
          - This is a Linux NixOS Machine
          - Its hostname is surface
          - The local network domain name is .lan
          - The local subnet is 192.168.178.0/24
          - The nix-shell can be used use to access tools for instance
              - `nix-shell --packages ethtool dnsutils --quiet --run "dig +short picard.lan"`
              - `ssh lwh-hotapril.lan 'nix-shell --packages facter --quiet --run "facter -j"'`
          - search for tools and applications with `nh search <application name>`
        '';
      };
      claude-obsidian = {
        enable = true;
      };
    };
  };

  # Stylix's obsidian target writes programs.obsidian.defaultSettings.appearance
  # and .cssSnippets, which home-manager symlinks into every enabled vault's
  # .obsidian/ dir (the nixos stylix module already injects stylix's home
  # module here, per the crann.stylix.enable in nix/modules/nixos/desktop.nix —
  # same reason crann's own test host disables stylix.targets.kde locally
  # rather than through crann.stylix.extraSettings). That symlink escapes the
  # vault root and trips claude-obsidian's vault-root-separation check
  # (PATH_OUTSIDE_VAULT) on adopt/init/every write, so keep Obsidian's own
  # settings files plain and mutable instead.
  stylix.targets.obsidian.enable = false;

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
