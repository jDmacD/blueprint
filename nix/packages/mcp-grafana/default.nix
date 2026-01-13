{
  pkgs,
  ...
}:
let
  src = ./grafana-mcp-wrapper.sh;
  binName = "grafana-mcp-wrapper";
  deps = [
    pkgs.mcp-grafana
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Grafana MCP server wrapper";
    };
  }
  ''
    mkdir -p $out/bin
    install -m 755 ${src} $out/bin/${binName}
    patchShebangs $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
