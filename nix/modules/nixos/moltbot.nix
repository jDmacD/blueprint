{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.moltbot.overlays.default ];
}
