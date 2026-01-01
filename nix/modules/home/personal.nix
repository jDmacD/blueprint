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
      sopsFile = ../../secrets/turing.yaml;
      path = "${config.home.homeDirectory}/.kube/turing";
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

    turingpi = {
      host = "turingpi.lan";
      user = "root";
      port = 22;
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    pis = {
      host = "tpi01.lan tpi02.lan tpi03.lan tpi04.lan pi01.lan pi02.lan pi03.lan pi05.lan";
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

    lwh-hotapril = {
      host = "lwh-hotapril";
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

    worf = {
      host = "worf";
      hostname = "worf.jtec.xyz";
      user = "jmacdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };

    gitlab = {
      host = "git";
      hostname = "git.heanet.ie";
      user = "james.macdonald";
      identityFile = config.sops.secrets.id_ed25519.path;
    };
  };
}
