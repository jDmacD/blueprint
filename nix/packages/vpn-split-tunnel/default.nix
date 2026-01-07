{
  pkgs,
  ...
}:
let
  src = ./vpn-split-tunnel.sh;
  binName = "vpn-split-tunnel";
  deps = [
    pkgs.networkmanager
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "NetworkManager dispatcher script for VPN split tunneling";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
