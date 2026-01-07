{
  config,
  lib,
  perSystem,
  ...
}:

with lib;

let
  cfg = config.networking.vpnSplitTunnel;
in
{
  options.networking.vpnSplitTunnel = {
    enable = mkEnableOption "automatic VPN split tunneling configuration";
  };

  config = mkIf cfg.enable {
    networking.networkmanager.dispatcherScripts = [
      {
        source = "${perSystem.self.vpn-split-tunnel}/bin/vpn-split-tunnel";
        type = "basic";
      }
    ];
  };
}
