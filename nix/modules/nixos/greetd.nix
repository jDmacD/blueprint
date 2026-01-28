# nix/modules/nixos/greetd.nix
{ flake, ... }:
{ pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  hyprstart = flake.packages.${system}.hyprstart or (throw "hyprstart not available for ${system}");

  session = "${hyprstart}/bin/hyprstart";
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
in
{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = session;
        user = "jmacdonald";
      };
      default_session = {
        command = "${tuigreet} --greeting 'Welcome to NixOS!' \
           --asterisks --remember --remember-user-session --time \
           -c ${session}";
        user = "greeter";
      };
    };
  };
}
