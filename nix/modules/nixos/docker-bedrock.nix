{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ipAddress = "37.27.34.153";
  server = {
    name = "Ted World";
    iconUrl = "https://i.imgur.com/nhumQVP.png";
    address = "bedrock.jtec.xyz";
    port = 19131;
  };
  serverList = [
    server
  ];
in
{
  system.activationScripts.makeBedrockDir = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/bedrock/data
    mkdir -p /var/lib/bedrock-connect/data
  '';

  virtualisation.oci-containers.containers.bedrock = {
    image = "itzg/minecraft-bedrock-server";
    pull = "always";
    ports = [
      "${toString server.port}:19132/udp"
    ];
    volumes = [
      "/var/lib/bedrock/data:/data"
    ];
    environment = {
      ALLOW_CHEATS = "true";
      EULA = "TRUE";
      DIFFICULTY = "1";
      SERVER_NAME = "Ted World";
      TZ = "Europe/Dublin";
      VERSION = "LATEST";
      OPS = "2533274808542325"; # Dissembler
    };
  };

  environment.etc."bedrock-connect/servers.json" = {
    mode = "0600";
    text = builtins.toJSON serverList;
  };

  virtualisation.oci-containers.containers.bedrock-connect = {
    image = "pugmatt/bedrock-connect";
    pull = "always";
    ports = [
      "19132:19132/udp"
    ];
    volumes = [
      "/var/lib/bedrock-connect/data:/data"
      "/etc/bedrock-connect/:/etc/bedrock-connect"
    ];
    environment = {
      BC_SERVER_LIMIT = "10";
      BC_CUSTOM_SERVERS = "/etc/bedrock-connect/servers.json";
    };
  };

  # Add networking configuration at the top level
  networking = {
    nameservers = [ "127.0.0.1" ]; # Use local unbound server
    resolvconf.enable = false; # Disable resolvconf
    dhcpcd.extraConfig = "nohook resolv.conf"; # Prevent DHCP from overwriting resolv.conf

    firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [
        53
        19132
      ];
    };
  };

  services = {
    resolved = {
      enable = false;
    };
    unbound = {
      enable = true;
      resolveLocalQueries = true;
      settings = {
        server = {
          access-control = [
            "0.0.0.0/0 allow"
            "::/0 allow"
          ]; # you might now want this open for recursion for everyone
          interface = [
            "0.0.0.0"
            "::"
          ];
          local-data = [
            ''"mco.lbsg.net. 10800 IN A ${ipAddress}"''
            ''"hivebedrock.network. 10800 IN A ${ipAddress}"''
            ''"geo.hivebedrock.network. 10800 IN A ${ipAddress}"''
            ''"play.inpvp.net. 10800 IN A ${ipAddress}"''
            ''"play.galaxite.net. 10800 IN A ${ipAddress}"''
            ''"play.enchanted.gg. 10800 IN A ${ipAddress}"''
          ];
          local-zone = [
            "mco.lbsg.net. static"
            "hivebedrock.network. static"
            "geohivebedrock.network. static"
            "play.inpvp.net. static"
            "play.galaxite.net. static"
            "play.enchanted.gg. static"
          ];
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = "1.1.1.1";
          }
        ];
      };
    };
  };

  # Add systemd timer services for container restarts
  systemd.services.restart-bedrock-containers = {
    description = "Restart Bedrock Minecraft containers";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "restart-containers" ''
        systemctl restart podman-bedrock
        sleep 5s
        systemctl restart podman-bedrock-connect
      '';
    };
  };

  systemd.timers.restart-bedrock-containers = {
    description = "Timer for restarting Bedrock Minecraft containers";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Unit = "restart-bedrock-containers.service";
    };
  };
}
