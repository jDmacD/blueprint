{
  config,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "jDmacD";
        email = "jmacdoo@gmail.com";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/personal.yaml;

    secrets.data = {
      # sops --age $(age-keygen -y ~/.age-key.txt) --output-type yaml -e ~/.kube/config | yq ".turing_kube_config = .data | del(.data)" > ~/.nix/secrets/turing.yaml
      sopsFile = ../../secrets/turing.yaml;
      path = "${config.home.homeDirectory}/.kube/config";
    };
    secrets.id_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };

    secrets.id_ed25519_pub = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
    };

    secrets.ha_id_rsa = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/ha_id_rsa";
    };

    secrets.turingpi_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/turingpi_ed25519";
    };

    secrets.pi4s_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/pi4s_ed25519";
    };

    secrets.opnsense_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/opnsense_ed25519";
    };
  };

  programs.ssh.matchBlocks = {
    ha = {
      host = "ha";
      hostname = "homeassistant.lan";
      user = "jmacd";
      port = 22;
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    tpi = {
      host = "tpi0*";
      user = "root";
      port = 22;
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    dietPi = {
      host = "pi04.lan";
      user = "root";
      port = 22;
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    nixPi = {
      host = "pi01.lan pi02.lan pi03.lan pi05.lan";
      user = "jmacdonald";
      port = 22;
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    opnsense = {
      host = "opn";
      hostname = "opnsense.lan";
      user = "jmacd";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    lwh = {
      host = "lwh";
      hostname = "lwh-hotapril.lan";
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    picard = {
      host = "picard";
      hostname = "picard.lan";
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    riker = {
      host = "riker";
      hostname = "riker.lan";
      user = "root";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    # prx = {
    #   host = "prx0*";
    #   user = "root";
    #   port = 22;
    #   identityFile = "~/.ssh/prx_ed25519";
    # };

    # pi400 = {
    #   host = "pi400.lan";
    #   user = "admin";
    #   port = 22;
    #   identityFile = "~/.ssh/pi400_rsa";
    # };

    # piload = {
    #   host = "piload*";
    #   user = "root";
    #   port = 22;
    #   identityFile = config.sops.secrets.piload_rsa.path;
    # };
  };
}
