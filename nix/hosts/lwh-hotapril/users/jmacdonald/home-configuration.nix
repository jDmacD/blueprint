{
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
      desktop
    ]
    ++ (with inputs.crann.modules.homeManager; [
      # niri's home config comes from the crann NixOS module via
      # home-manager.sharedModules, as on surface.
      git
      kubernetes
      shells
      terminal
      nix-utils
      obsidian
      ai-utils
      vault-sync
    ]);

  crann = {
    git.enable = true;
    kubernetes.enable = true;
    shells = {
      enable = true;
      flakeInspectPath = "${config.home.homeDirectory}/blueprint";
    };
    terminal.enable = true;
    nix-utils = {
      enable = true;
      nh = {
        flakePath = "${config.home.homeDirectory}/blueprint";
      };
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
          - Its hostname is lwh-hotapril
          - The local network domain name is .lan
          - The local subnet is 192.168.178.0/24
          - The user's timezone is Europe/Dublin (IST, UTC+1, in summer; GMT, UTC+0, in winter). Clusters, logs and alerts use UTC, so give the user times in local time too
          - The nix-shell can be used use to access tools for instance
              - `nix-shell --packages ethtool dnsutils --quiet --run "dig +short picard.lan"`
              - `ssh picard.lan 'nix-shell --packages facter --quiet --run "facter -j"'`
          - search for tools and applications with `nh search <application name>`
        '';
      };
      claude-obsidian = {
        enable = true;
      };
    };
  };

  # Blank the screen after 10 minutes idle. noctalia's built-in idle
  # behaviors (lock, screen-off, lock-and-suspend) all default to disabled;
  # only screen-off is turned on, since this host must never suspend.
  crann.noctalia.extraSettings.idle.behavior.screen-off = {
    enabled = true;
    timeout = 600;
    action = "screen_off";
  };

  # bitwarden_secret is decrypted at the NixOS level, as on surface.
  programs.zsh.initContent = ''
    export BWS_ACCESS_TOKEN="$(cat ${osConfig.sops.secrets.bitwarden_secret.path})"
  '';
  programs.bash.initExtra = ''
    export BWS_ACCESS_TOKEN="$(cat ${osConfig.sops.secrets.bitwarden_secret.path})"
  '';

  home.stateVersion = "25.11";

  crann.vault-sync = {
    enable = true;
    remote = "ssh://git@codeberg.org/jDmacD/technodrome.git";
    rerankOllamaUrl = "https://ollama.local.jtec.xyz";
    rerankApproval = "jDmacD has given standing approval (2026-10-11)";
    recall.vaultDescription = "jDmacD's second brain and project tracker";
  };
}
