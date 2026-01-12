{ config, ... }:
{
  sops.secrets."acme/cloudflare" = {

  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@jtec.xyz";
    certs."${config.networking.hostName}.jtec.xyz" = {
      dnsProvider = "cloudflare";
      environmentFile = "/run/secrets/acme/cloudflare";
    };
  };
}
