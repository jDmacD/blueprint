{ flake, inputs, ... }:
{
  imports = [
    ../modules/nixos/greetd.nix
  ];
}
