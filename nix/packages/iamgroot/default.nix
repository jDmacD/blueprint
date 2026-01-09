{
  pkgs,
  ...
}:
let
  app = pkgs.writeShellScriptBin "iamgroot" ''
    while true; do
      echo "I Am Groot"
      sleep 5
    done
  '';
in

pkgs.dockerTools.buildImage {
  name = "iamgroot";
  tag = "latest";
  config = {
    Cmd = [ "${app}/bin/iamgroot" ];
  };
}
