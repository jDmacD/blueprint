{
  pkgs,
  ...
}:
let
  app = pkgs.writeShellApplication {
    name = "iamgroot";
    runtimeInputs = [ pkgs.coreutils ];
    text = ./iamgroot.sh;
  };
in
pkgs.dockerTools.buildImage {
  name = "iamgroot";
  tag = "latest";
  config = {
    Cmd = [ "${app}/bin/iamgroot" ];
  };
}
