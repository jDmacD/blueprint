{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.openclaw.overlays.default ];
}
