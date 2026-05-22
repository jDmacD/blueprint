{
  inputs,
  ...
}:

{
  imports = [ inputs.eduvpn.nixosModules.default ];

  security.acme.acceptTerms = true;

  networking = {
    firewall = {
      enable = true;
      # "loose" allows WireGuard reverse-path filtering without disabling it entirely.
      checkReversePath = "loose";
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 51820 ];
    };
    nftables = {
      enable = true;
      # Masquerade VPN client ranges through the server's uplink.
      # Update these if you change the wRangeFour / wRangeSix profile options.
      ruleset = ''
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip saddr 10.43.43.0/24 masquerade;
          }
        }
        table ip6 nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip6 saddr fd43::/64 masquerade;
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
      tls.acmeEmail = "badgerblitz@tuta.com"; # replace with your contact email
      profiles = [
        {
          profileId = "default";
          displayName = "Default";
          hostName = "worf.jtec.xyz";
          wRangeFour = "10.10.0.0/24";
          wRangeSix = "fd10::/64";
        }
      ];
    };
    node.enable = true;
  };
}
