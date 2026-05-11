{
  pkgs,
  config,
  perSystem,
  ...
}:
{

  home.packages =
    with pkgs;
    [
      cachix
      deploy-rs
      nixos-rebuild-ng
      nixos-anywhere
      # disko
    ]
    ++ (with perSystem.self; [ cachix-update ]);

  programs.nh = {
    enable = true;
    darwinFlake = "${config.home.homeDirectory}/blueprint";
    flake = "${config.home.homeDirectory}/blueprint";
  };
}
