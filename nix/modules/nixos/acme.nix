{ config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@jtec.xyz";
    certs."${config.hostName}.jtec.xyz" = {
      dnsProvider = "cloudflare";
    };
  };
}
