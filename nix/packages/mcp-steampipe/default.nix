{
  pkgs,
  ...
}:
let
  src = ./steampipe-mcp-wrapper.sh;
  binName = "steampipe-mcp-wrapper";
  deps = [
    pkgs.kubectl
    pkgs.netcat
    pkgs.nodejs_22
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Steampipe MCP server wrapper with kubectl port-forward";
    };
  }
  ''
    mkdir -p $out/bin
    install -m 755 ${src} $out/bin/${binName}
    patchShebangs $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
