{ pkgs, inputs, ... }:
if pkgs.stdenv.hostPlatform.system != "aarch64-linux" then
  pkgs.runCommand "config-php-worf-skip" { } "touch $out"
else
  inputs.eduvpn.lib.mkConfigPhpCheck "worf" inputs.self.nixosConfigurations.worf pkgs
