{
  pkgs,
  osConfig,
  config,
  inputs,
  ...
}:
{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.packages = with pkgs; [
    sops
  ];
}
