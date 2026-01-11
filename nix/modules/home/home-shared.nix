{
  pkgs,
  osConfig,
  ...
}:
{

  imports = [ ];

  programs = {
    home-manager = {
      enable = true;
    };
  };

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  home.packages =
    with pkgs;
    [ virt-manager ]
    ++ (
      # you can access the host configuration using osConfig.
      pkgs.lib.optionals (osConfig.programs.vim.enable && pkgs.stdenv.isDarwin) [ skhd ]
    );
}
