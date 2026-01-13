{
  config,
  pkgs,
  perSystem,
  ...
}:
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

  # Register domain in DNS before ACME tries to obtain certificates
  systemd.services.register-domain = {
    description = "Register hostname DNS record in Cloudflare";
    wantedBy = [ "multi-user.target" ];
    before = [ "acme-${config.networking.hostName}.jtec.xyz.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${perSystem.self.register-domain}/bin/register-domain";
      EnvironmentFile = "/run/secrets/acme/cloudflare";
    };
  };
}
