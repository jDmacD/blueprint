{ flake, inputs, ... }:
{ pkgs, ... }:
{
  imports = [
    ../modules/nixos/greetd.nix
  ];

  # Override to use hyprstart from THIS flake (not consumer's flake)
  services.greetd.settings = {
    initial_session.command = "${flake.packages.${pkgs.system}.hyprstart}";
    default_session.command =
      let tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
      in "${tuigreet} --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time -c ${flake.packages.${pkgs.system}.hyprstart}";
  };
}
