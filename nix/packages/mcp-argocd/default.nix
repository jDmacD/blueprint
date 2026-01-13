{
  pkgs,
  ...
}:
let
  src = ./argocd-mcp-wrapper.sh;
  binName = "argocd-mcp-wrapper";
  deps = [
    pkgs.nodejs_22
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "ArgoCD MCP server wrapper";
    };
  }
  ''
    mkdir -p $out/bin
    install -m 755 ${src} $out/bin/${binName}
    patchShebangs $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
