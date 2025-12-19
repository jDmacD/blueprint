{
  pkgs,
  inputs,
  osConfig,
  config,
  perSystem,
  ...
}:
{

  imports = [ ];

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  home.packages =
    with pkgs;
    [ ]
    ++ (
      # you can access the host configuration using osConfig.
      pkgs.lib.optionals (osConfig.programs.vim.enable && pkgs.stdenv.isDarwin) [ skhd ]
    )
    ++ (with perSystem.self; [ ]);
}
