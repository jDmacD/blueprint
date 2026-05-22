{
  inputs,
  ...
}:

{
  imports = [ inputs.eduvpn.nixosModules.default ];

  security.acme.acceptTerms = true;

  services.eduVPN = {
    portal = {
      enable = true;
      hostName = "worf.jtec.xyz";
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
