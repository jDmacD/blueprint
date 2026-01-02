{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{

  imports = [
    ./github-runner-user.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {

    settings = {
      experimental-features = "nix-command flakes";
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    extraOptions = ''
      # Ensure we can still build when missing-server is not accessible
      fallback = true
    '';
  };

  # console.keyMap = "ukext";

  time.timeZone = "Europe/Dublin";

  /*
    This is for checking and updating firmware
    fwupdmgr refresh
    fwupdmgr get-updates
    fwupdmgr update
  */
  services = {
    udisks2.enable = pkgs.stdenv.isLinux;
    fwupd.enable = pkgs.stdenv.isLinux;
  };

  # you can check if host is darwin by using pkgs.stdenv.isDarwin
  environment.systemPackages = [
    pkgs.git
  ]
  ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.xbar ]);
}
