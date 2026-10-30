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
    inputs.crann.modules.homeManager.obsidian
    inputs.crann.modules.homeManager.ai-utils
    inputs.crann.modules.homeManager.vault-sync
  ]
  ++ (with inputs.self.homeModules; [
    home-shared
    cluster-sweep
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
    obsidian = {
      enable = true;
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
      mcp.grafana = {
        enable = true;
        # LAN-only route; grafana.jtec.xyz is behind Cloudflare Access.
        url = "https://grafana.local.jtec.xyz";
        tokenFile = config.sops.secrets.grafana_mcp_token.path;
        # Write tools are needed to create and update dashboards.
        readOnly = false;
      };
      # Grafana alerts pushed into a `claude-alerts` session. Grafana's
      # "Claude" webhook contact point posts to picard.lan:8788. picard's
      # firewall is off (k3s-agent-gpu), so the bearer token is the only gate.
      channels.grafana = {
        enable = true;
        host = "192.168.178.103";
        tokenFile = config.sops.secrets.grafana_channel_token.path;
      };
    };
  };

  # Editor-role service account token (Grafana > Administration > Service accounts).
  sops.secrets.grafana_mcp_token = { };
  # Bearer token for the Claude contact point (Authorization header credentials).
  sops.secrets.grafana_channel_token = { };

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

  crann.vault-sync = {
    enable = true;
    remote = "ssh://git@codeberg.org/jDmacD/technodrome.git";
    rerankOllamaUrl = "https://ollama.local.jtec.xyz";
    rerankApproval = "jDmacD has given standing approval (2026-10-11)";
    recall.vaultDescription = "jDmacD's second brain and project tracker";
  };

  cluster-sweep.enable = true;
}
