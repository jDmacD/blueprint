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
    inputs.jtec-mcp.homeManagerModules.default
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
    # Shared Noctalia desktop (crann's desktop.toml). This host's layer:
    # Immich wallpapers for the 3840x1600 DP-1, from the two ultrawide tags.
    noctalia = {
      desktop.enable = true;
      hostSettings.plugin_settings."jdmacd/immich-wallpaper".tags = [
        "wallpapers/3840x1600"
        "wallpapers/3440x1440"
      ];
    };
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
          - jtec-mcp (`mcp__jtec__*` tools; repo `~/Code/jtec-mcp`, github.com/jDmacD/jtec-mcp) is jDmacD's MCP server for cluster and home services. Use it before calling a service's API by hand. When a task needs a service API by hand (curl, `kubectl exec`, port-forwards, ad-hoc scripts) for a step likely to recur, extend jtec-mcp proactively: finish the user's task first, then open a branch + PR in jtec-mcp following its CLAUDE.md (prefer a maintained Python library, then the service's OpenAPI/Swagger spec, then hand-written httpx). jDmacD wants this without being asked; say in one line that you opened it.
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

  # jtec-mcp: API keys come from BWS via secretspec; the server reads only
  # the BWS access token (Claude's `bws.claude` machine-account token).
  services.jtec-mcp = {
    enable = true;
    settings.services.slskd = {
      # LAN-only route on the internal gateway.
      url = "https://slskd.local.jtec.xyz";
      key_field = "SLSKD_API_KEY";
    };
    # BWS project `jtec`, the one the cluster's external-secrets store reads.
    secretspec.provider = "bws://f2fc98e1-f97e-4cd2-bedf-b24c00954124";
    secretFiles.BWS_ACCESS_TOKEN = config.sops.secrets."bws/claude".path;
  };
  sops.secrets."bws/claude" = { };

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
