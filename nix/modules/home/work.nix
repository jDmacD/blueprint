{
  config,
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  home.packages =
    [ ]
    ++ (with pkgs; [
      docker-compose
      steampipe
      glab
      rancher
      cilium-cli
      hubble
      awscli2
      azure-cli
      eksctl
      vault
      devbox
      wireshark
      stoken
      filezilla
      ipcalc
      freerdp
      remmina
      pgcli
      argo-rollouts
      uv
      pre-commit
      kubeconform
      microsoft-edge
      vhs
      asciinema
      asciinema-agg
    ])
    ++ (with perSystem.nixpkgs-stable; [
      mycli
    ]);

  programs.zsh = {
    shellAliases = {
      eduvpn = "env -u GI_TYPELIB_PATH eduvpn-cli interactive";
    };
  };

  programs.git = {
    settings.user.name = "james.macdonald";
    settings.user.email = "james.macdonald@heanet.ie";
  };

  sops = {
    defaultSopsFile = ../../secrets/work.yaml;

    secrets.id_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };

    secrets.id_ed25519_pub = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
    };

    secrets.heanet_id_rsa = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/heanet_id_rsa";
    };

    secrets.gitlab_bastion_pem = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/gitlab-bastion.pem";
    };

    secrets.media_bastion_rsa = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/media_bastion_rsa";
    };

    secrets.aws_config = {
      path = "${config.home.homeDirectory}/.aws/config";
    };

    secrets.aws_credentials = {
      path = "${config.home.homeDirectory}/.aws/credentials";
    };

    secrets.glab_cli_alias_yml = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.config/glab-cli/aliases.yml";
    };

    secrets.glab_cli_config_yml = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.config/glab-cli/config.yml";
    };

    secrets.nix_conf = {
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
    secrets.hcloud = {
      path = "${config.home.homeDirectory}/.config/hcloud/cli.toml";
    };
  };

  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    heanet = {
      host = "*.heanet.ie";
      user = "heanet";
      identityFile = config.sops.secrets.heanet_id_rsa.path;
    };

    jumpOff = {
      host = "jo";
      hostname = "jo.heanet.ie";
      user = "jmacdonald";
      identityFile = config.sops.secrets.heanet_id_rsa.path;
    };

    oireachtas = {
      host = "oireachtas";
      hostname = "13.69.138.59";
      user = "heanet";
      identityFile = config.sops.secrets.heanet_id_rsa.path;
    };

    mediaAwsBastion = {
      host = "media-aws-bastion";
      hostname = "media-aws-bastion.heanet.ie";
      user = "ubuntu";
      identityFile = config.sops.secrets.media_bastion_rsa.path;
    };

    control = {
      host = "control";
      hostname = "87.44.74.162";
      user = "heanet";
      identityFile = config.sops.secrets.heanet_id_rsa.path;
    };

    k8s-bastion = {
      host = "k8s-bastion";
      hostname = "193.1.244.11";
      port = 22;
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    elba1 = {
      host = "elba1";
      hostname = "193.1.236.5";
      port = 22;
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    elba2 = {
      host = "elba2";
      hostname = "193.1.236.7";
      port = 22;
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    gitlabProductionBastion = {
      host = "gitlab-production-bastion";
      hostname = "34.240.7.201";
      port = 22;
      user = "ubuntu";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      # controlPersist = "5m";
      # controlMaster = "auto";
      forwardAgent = true;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabProductionA = {
      host = "gitlab-production-a";
      hostname = "10.0.1.234";
      user = "ubuntu";
      proxyJump = "gitlab-production-bastion";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabProductionB = {
      host = "gitlab-production-b";
      hostname = "10.0.3.192";
      user = "ubuntu";
      proxyJump = "gitlab-production-bastion";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabGitalyProduction = {
      host = "gitlab-gitaly-production";
      hostname = "10.0.1.94";
      user = "ubuntu";
      proxyJump = "gitlab-production-bastion";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabStagingBastion = {
      host = "gitlab-staging-bastion";
      hostname = "18.197.57.238";
      port = 22;
      user = "ubuntu";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      # controlPersist = "5m";
      # controlMaster = "auto";
      forwardAgent = true;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabStagingA = {
      host = "gitlab-staging-a";
      hostname = "10.0.1.148";
      user = "ubuntu";
      proxyJump = "gitlab-staging-bastion";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };

    gitlabStagingB = {
      host = "gitlab-staging-b";
      hostname = "10.0.3.46";
      user = "ubuntu";
      proxyJump = "gitlab-staging-bastion";
      identityFile = config.sops.secrets.gitlab_bastion_pem.path;
      extraOptions = {
        StrictHostKeyChecking = "no";
      };
    };
  };

  home.file = {
    ".local/share/applications/outlook.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Outlook Mail
      Comment=Outlook Mail
      Exec=xdg-open "https://outlook.office.com"
      Icon=mail
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/gitlab.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Gitlab
      Comment=HEAnet Gitlab
      Exec=xdg-open "https://git.heanet.ie"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/rancher.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Rancher
      Comment=HEAnet Rancher
      Exec=xdg-open "https://rancher.k3s.heanet.ie"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/argocd.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=ArgoCD
      Comment=HEAnet ArgoCD
      Exec=xdg-open "https://argocd.k3s.heanet.ie"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/vmware.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=vmWare
      Comment=vmWare web interface
      Exec=xdg-open "https://vmware-host-vcentre-01.heanet.ie"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/bamboohr.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Bamboo HR
      Comment=Babmboo HR
      Exec=xdg-open "https://heanet.bamboohr.com"
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
    ".local/share/applications/eduvpn.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=EduVPN
      Comment=EduVPN GUI
      Exec=eduvpn-gui
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Application;
    '';
  };
}
