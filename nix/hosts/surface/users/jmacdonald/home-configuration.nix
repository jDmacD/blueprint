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
      vault-sync
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
          - The user's timezone is Europe/Dublin (IST, UTC+1, in summer; GMT, UTC+0, in winter). Clusters, logs and alerts use UTC, so give the user times in local time too
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

  # programs.noctalia-shell.wallpaper.monitorDirectories = [
  #   {
  #     name = "eDP-1";
  #     dimensions = "3000x2000";
  #     wallpaper = "wallhaven-n6kwqx_3000x2000.png";
  #   }
  # ];

  # bitwarden_secret is decrypted at the NixOS level (nix/hosts/secrets.yaml,
  # sops.secrets."bitwarden_secret" in configuration.nix) since it's shared
  # across all hosts' host keys, not the personal-only home-manager sops file.
  programs.zsh.initContent = ''
    export BWS_ACCESS_TOKEN="$(cat ${osConfig.sops.secrets.bitwarden_secret.path})"
  '';
  programs.bash.initExtra = ''
    export BWS_ACCESS_TOKEN="$(cat ${osConfig.sops.secrets.bitwarden_secret.path})"
  '';

  home.packages = with pkgs; [
    # blender
    # inkscape
  ];

  home.stateVersion = "26.05";

  crann.vault-sync = {
    enable = true;
    remote = "ssh://git@codeberg.org/jDmacD/technodrome.git";
    rerankOllamaUrl = "https://ollama.local.jtec.xyz";
    rerankApproval = "jDmacD has given standing approval (2026-10-11)";
    recall.vaultDescription = "jDmacD's second brain and project tracker";
  };
}
