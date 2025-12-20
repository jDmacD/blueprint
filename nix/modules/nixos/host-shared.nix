{ pkgs, inputs, lib, config, ... }:
{

  imports = [
    ./github-runner-user.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
          "https://jdmacd.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "jdmacd.cachix.org-1:0DcSfXShBIng2EbPW44fxoXjXowKhZZWrbYqcozFhfM="
        ];
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      extraOptions = ''
        # Ensure we can still build when missing-server is not accessible
        fallback = true
      '';
    };

  # console.keyMap = "ukext";
  services = {
    xserver = {
      enable = false;
      xkb = {
        layout = "gb";
        variant = "intl";
      };
    };
  };

  time.timeZone = "Europe/Dublin";

  # you can check if host is darwin by using pkgs.stdenv.isDarwin
  environment.systemPackages = [
    pkgs.git
  ]
  ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.xbar ]);
}
