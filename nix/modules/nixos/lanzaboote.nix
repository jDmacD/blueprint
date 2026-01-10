{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # https://nix-community.github.io/lanzaboote/introduction.html#prerequisites
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    # https://nix-community.github.io/lanzaboote/how-to-guides/automatically-generate-keys.html
    autoGenerateKeys.enable = true;
    # https://nix-community.github.io/lanzaboote/how-to-guides/automatically-enroll-keys.html
    autoEnrollKeys = {
      enable = true;
    };
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
