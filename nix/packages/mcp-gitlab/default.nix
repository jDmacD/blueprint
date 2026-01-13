{
  pkgs,
  ...
}:
let
  src = ./gitlab-mcp-wrapper.sh;
  binName = "gitlab-mcp-wrapper";
  deps = [
    pkgs.nodejs_22
    pkgs.yq-go
  ];
in
pkgs.runCommand "${binName}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      mainProgram = "${binName}";
      description = "Gitlab MCP server wrapper";
    };
  }
  ''
    patchShebangs ${src}
    mkdir -p $out/bin
    install -m +x ${src} $out/bin/${binName}
    wrapProgram $out/bin/${binName} \
      --prefix PATH : ${pkgs.lib.makeBinPath deps}
  ''
