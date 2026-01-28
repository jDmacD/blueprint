# nix/packages/hyprstart/default.nix
{
  pkgs,
  ...
}:
let
  uwsm = "${pkgs.hyprland}/bin/uwsm";
in
pkgs.writeShellScriptBin "hyprstart" ''

  if ${uwsm} check may-start && ${uwsm} select; then
  	exec ${uwsm} start default
  fi 
''
