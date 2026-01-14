{
  pkgs,
  ...
}:
let
  src = ./register-domain.sh;
  binName = "register-domain";
  deps = with pkgs; [
    hostname
    iproute2
    gawk
    dnsutils
    cloudflare-cli
    jq
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Register the local IP with Cloudflare domain";
    };
  }
  ''
    mkdir -p $out/bin
    install -m 755 ${src} $out/bin/${binName}
    patchShebangs $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
