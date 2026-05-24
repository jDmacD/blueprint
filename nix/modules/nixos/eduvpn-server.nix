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
      ruleset = ''
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip saddr 10.10.0.0/24 masquerade;
            ip saddr 10.10.1.0/24 masquerade;
          }
        }
        table ip6 nat {
          chain postrouting {
            type nat hook postrouting priority srcnat;
            ip6 saddr fd10::/64 masquerade;
            ip6 saddr fd11::/64 masquerade;
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
          # wRangeFour = "10.10.0.0/24";
          # wRangeSix = "fd10::/64";
          oRangeFour = "10.10.1.0/24";
          oRangeSix = "fd11::/64";
          defaultGateway = true;
          dnsServerList = [
            "9.9.9.9"
            "2620:fe::fe"
          ];
        }
      ];
      prometheus.enable = true;
      # singleProcess = true generates "local :: 1194 udp" syntax that requires
      # openvpn 2.7+; nixpkgs ships 2.6.x. Re-enable when nixpkgs catches up.
      # settings = {
      #   OpenVpn = {
      #     singleProcess = true;
      #   };
      # };
    };
    node = {
      enable = true;
      wireguard.enable = false;
      proxyguard.enable = false;
      openvpn.enable = true;
    };
  };
}
