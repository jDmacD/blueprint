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
    patchShebangs ${src}
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
