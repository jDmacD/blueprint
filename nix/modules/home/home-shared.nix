{
  pkgs,
  inputs,
  osConfig,
  config,
  ...
}:
{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./terminal.nix
    ./firefox.nix
    ./vscode.nix
  ];

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.packages = [
    pkgs.devbox
    pkgs.pre-commit
    pkgs.sops
  ]
  ++ (
    # you can access the host configuration using osConfig.
    pkgs.lib.optionals (osConfig.programs.vim.enable && pkgs.stdenv.isDarwin) [ pkgs.skhd ]
  );

  home.stateVersion = "25.11"; # initial home-manager state
}
