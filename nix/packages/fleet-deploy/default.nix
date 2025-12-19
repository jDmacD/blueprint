{
  pkgs,
  ...
}:
pkgs.writeShellScriptBin "fleet-deploy" ''
  echo "hello"
''
