{
  pkgs,
  ...
}:
let
  src = ./backup-k3s-db.sh;
  binName = "backup-k3s-db";
  deps = [
    pkgs.gum
    pkgs.rsync
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
