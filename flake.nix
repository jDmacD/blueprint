{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixpkgs-25-05.url = "github:NixOS/nixpkgs?ref=25.05";
    nixpkgs-24-11.url = "github:NixOS/nixpkgs?ref=24.11";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-25-05.url = "github:nix-community/home-manager/release-25.05";
    home-manager-25-05.inputs.nixpkgs.follows = "nixpkgs-25-05";

    hyprland.url = "github:hyprwm/Hyprland";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # this is purely for the uconsole
    oom-hardware-nixos-raspberrypi.url = "github:robertjakub/nixos-raspberrypi/develop"; # stick with my branch
    oom-hardware-nixos-raspberrypi.inputs.nixpkgs.follows = "nixpkgs";
    oom-hardware.url = "github:robertjakub/oom-hardware/devel";
    oom-hardware.inputs.nixpkgs.follows = "nixpkgs";
    oom-hardware.inputs.nixos-raspberrypi.follows = "nixos-raspberrypi";

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    attic.url = "github:zhaofengli/attic"
    attic.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://jdmacd.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "jdmacd.cachix.org-1:0DcSfXShBIng2EbPW44fxoXjXowKhZZWrbYqcozFhfM="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  # Load the blueprint
  outputs =
    inputs:
    let
      bp = inputs.blueprint {
        inherit inputs;
        systems = [
          "aarch64-linux"
          "x86_64-linux"
          "aarch64-darwin"
        ];
        prefix = "nix/";
      };
    in
    {
      inherit (bp)
        lib
        nixosConfigurations
        darwinConfigurations
        nixosModules
        darwinModules
        homeModules
        packages
        devShells
        checks
        ;
      deploy = {
        nodes =
          let
            mkNode =
              {
                name,
                hostname ? "${name}.lan",
                sshUser ? "jmacdonald",
                user ? "root",
                arch ? "aarch64-linux",
                remoteBuild ? false,
              }:
              let
                isDarwin = builtins.match ".*-darwin" arch != null;
                activator = if isDarwin then "darwin" else "nixos";
                configurations = if isDarwin then bp.darwinConfigurations else bp.nixosConfigurations;
              in
              {
                inherit
                  hostname
                  sshUser
                  user
                  remoteBuild
                  ;
                profiles.system = {
                  path = inputs.deploy-rs.lib.${arch}.activate.${activator} configurations.${name};
                };
              };
          in
          {
            picard = mkNode {
              name = "picard";
              arch = "x86_64-linux";
            };
            worf = mkNode {
              name = "worf";
              hostname = "worf.jtec.xyz";
              remoteBuild = true;
            };
            # uconsole = mkNode { name = "uconsole"; };
            pi01 = mkNode { name = "pi01"; };
            pi02 = mkNode { name = "pi02"; };
            pi03 = mkNode { name = "pi03"; };
            pi04 = mkNode { name = "pi04"; };
            pi05 = mkNode { name = "pi05"; };
            tpi01 = mkNode { name = "tpi01"; };
            tpi02 = mkNode { name = "tpi02"; };
            tpi03 = mkNode { name = "tpi03"; };
            tpi04 = mkNode { name = "tpi04"; };
          };
      };
    };
}
