{
  pkgs,
  ...
}:
let
  version = "0.9.12";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "kagent";
  inherit version;

  # Prebuilt, statically linked Go binary from the upstream release.
  src = pkgs.fetchurl {
    url = "https://github.com/kagent-dev/kagent/releases/download/v${version}/kagent-linux-amd64";
    hash = "sha256-r8Op8r3tQHU4TNbVnE1yfCLuSrkh15zlLrzgBO4WsaE=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/kagent
    runHook postInstall
  '';

  meta = {
    description = "CLI for kagent - Bringing Agentic AI to cloud native";
    homepage = "https://github.com/kagent-dev/kagent";
    license = pkgs.lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kagent";
  };
}
