{
  inputs,
  pkgs,
  ...
}:
let
  wRangeFour = "10.10.0.0/24";
  wRangeSix = "fd10::/64";
  oRangeFour = "10.10.1.0/24";
  oRangeSix = "fd11::/64";
in
{
  imports = [ inputs.eduvpn.nixosModules.default ];

  security.acme.acceptTerms = true;

  networking = {
    firewall = {
      enable = true;
      # "loose" allows WireGuard reverse-path filtering without disabling it entirely.
      # TCP 80/443 and WireGuard UDP 51820 are opened automatically by the eduVPN modules.
      # OpenVPN ports are opened automatically when openvpn.enable = true.
      checkReversePath = "loose";
    };
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip saddr ${wRangeFour} masquerade;
            ip saddr ${oRangeFour} masquerade;
          }
        }
        table ip6 nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip6 saddr ${wRangeSix} masquerade;
            ip6 saddr ${oRangeSix} masquerade;
          }
        }
      '';
    };
  };

  services.eduVPN = {
    portal = {
      enable = true;
      hostName = "worf.jtec.xyz";
      adminUsers = [ "admin" ];
      tls.useACME = true;
      tls.acmeEmail = "badgerblitz@tuta.com";
      secretsJsonFile = "/run/secrets/eduvpn/portal_secrets.json";
      profiles = [
        {
          profileId = "default";
          displayName = "Default";
          hostName = "worf.jtec.xyz";
          wRangeFour = wRangeFour;
          wRangeSix = wRangeSix;
          oRangeFour = oRangeFour;
          oRangeSix = oRangeSix;
          defaultGateway = true;
          preferredProto = "wireguard";
          dnsServerList = [
            "9.9.9.9"
            "2620:fe::fe"
          ];
        }
      ];
      prometheus.enable = true;
      /*
        singleProcess = true generates "local :: 1194 udp" syntax that requires
        openvpn 2.7+; nixpkgs ships 2.6.x. Re-enable when nixpkgs catches up.
        settings = {
          OpenVpn = {
            singleProcess = true;
          };
        };
      */
    };
    node = {
      enable = true;
      wireguard.enable = true;
      openvpn.enable = true;
      proxyguard.enable = false;
    };
  };

  sops.secrets = {
    /*
      CREATE USER eduvpn WITH PASSWORD 'secretpassword';
      GRANT ALL PRIVILEGES ON DATABASE eduvpn TO eduvpn;
      \c eduvpn
      GRANT ALL ON SCHEMA public TO eduvpn;
    */
    "eduvpn/postgres_initial.sql" = {
      owner = "postgres";
    };
    /*
      {
        "Db": {
          "dbDsn": "pgsql:host=127.0.0.1;dbname=eduvpn;user=eduvpn;password=secretpassword"
        }
      }
    */
    "eduvpn/portal_secrets.json" = {
      owner = "wwwrun";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "eduvpn" ];
    initialScript = "/run/secrets/eduvpn/postgres_initial.sql";
  };
}
