# nix/modules/nixos/greetd.nix
{ flake, inputs , ...}:
{ pkgs, perSystem, ... }:
let
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  session = "${perSystem.self.hyprstart}/bin/hyprstart";
  username = "jmacdonald";
in
{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = session;
        user = username;
      };
      default_session = {
        command =
          "${tuigreet} --greeting 'Welcome to NixOS!' \
           --asterisks --remember --remember-user-session --time \
           -c ${session}";
        user = "greeter";
      };
    };
  };
}
