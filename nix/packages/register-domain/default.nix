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
    patchShebangs ${src}
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
