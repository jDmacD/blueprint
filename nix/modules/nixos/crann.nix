{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = with inputs.crann.modules.nixos; [
    optnix
  ];

  crann = {
    optnix = {
      enable = true;
    };
  };
}
