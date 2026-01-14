{
  pkgs,
  ...
}:
pkgs.buildGoModule {
  name = "hello";
  src = ./src;
  vendorHash = "sha256-uwBJAqN4sIepiiJf9lCDumLqfKJEowQO2tOiSWD3Fig=";
}
