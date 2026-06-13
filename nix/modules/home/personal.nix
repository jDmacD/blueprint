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

    secrets.coderberg_ed25519 = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.ssh/coderberg_ed25519";
    };

  };

  # `programs.ssh.settings` replaces the deprecated `matchBlocks`. The attribute
  # name is the `Host` pattern, and values use upstream OpenSSH directive names.
  programs.ssh.settings = {

    "surface.lan" = {
      User = "jmacdonald";
      Port = 22;
      IdentityFile = config.sops.secrets.id_ed25519.path;
      ForwardX11 = true;
      ForwardX11Trusted = true;
    };

    "ha" = {
      HostName = "homeassistant.lan";
      User = "jmacd";
      Port = 22;
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "turingpi.lan" = {
      User = "root";
      Port = 22;
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "tpi01.lan tpi02.lan tpi03.lan tpi04.lan pi01.lan pi02.lan pi03.lan pi05.lan" = {
      User = "jmacdonald";
      Port = 22;
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "opn" = {
      HostName = "opnsense.lan";
      User = "jmacd";
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "lwh-hotapril" = {
      HostName = "lwh-hotapril.lan";
      User = "jmacdonald";
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "picard" = {
      HostName = "picard.lan";
      User = "jmacdonald";
      ForwardX11 = true;
      ForwardX11Trusted = true;
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "riker" = {
      HostName = "riker.lan";
      User = "root";
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "worf" = {
      HostName = "worf.jtec.xyz";
      User = "jmacdonald";
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "git" = {
      HostName = "git.heanet.ie";
      User = "james.macdonald";
      IdentityFile = config.sops.secrets.id_ed25519.path;
    };

    "codeberg.org" = {
      HostName = "codeberg.org";
      User = "jDmacD";
      IdentityFile = config.sops.secrets.coderberg_ed25519.path;
    };
  };
}
