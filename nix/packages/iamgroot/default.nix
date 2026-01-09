{
  pkgs,
  ...
}:
let
  app = pkgs.writeShellScriptBin "iamgroot" ''
    echo "I Am Groot"
  '';
in

pkgs.dockerTools.buildImage {
  name = "iamgroot";
  tag = "latest";
  config = {
    Cmd = [ "${app}/bin/iamgroot" ];
  };
}
