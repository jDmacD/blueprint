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
    patchShebangs ${src}
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
