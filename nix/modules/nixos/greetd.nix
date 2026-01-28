{ flake, inputs, ... }:  # ← Outer function: Blueprint calls this with YOUR flake
{ pkgs, perSystem, ... }:  # ← Inner function: The actual NixOS module

let
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  # Use flake from outer scope - always refers to THIS flake
  session = "${flake.packages.${pkgs.system}.hyprstart}";
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
        command = "${tuigreet} --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time -c ${session}";
        user = "greeter";
      };
    };
  };
}
