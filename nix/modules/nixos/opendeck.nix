{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  opendeckUdev = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/OpenActionAPI/rust-elgato-streamdeck/main/40-streamdeck.rules";
    sha256 = "sha256-kxIzSbFTTzLXCfjuNvqBh+6SHCrvr31d84UUFxtHUBg=";
  };
in
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];
  services.flatpak = {
    enable = true;
    # flatpak 1.18.0 (nixpkgs-unstable) has a portal regression: `flatpak-spawn
    # --sandbox` no longer sets a default PATH, so glycin's image-loader
    # subprocess (invoked via `env -i … flatpak-spawn --sandbox … prlimit …`)
    # can't resolve the bare `prlimit`, exits 1, and every GTK4 flatpak that
    # loads an icon (e.g. OpenDeck) crashes on startup. Pin to the 1.16.x
    # series until upstream fixes the portal.
    package = perSystem.nixpkgs-25-11.flatpak;
    packages = [
      {
        appId = "me.amankhanna.opendeck";
        origin = "flathub";
      }
    ];
  };
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "opendeck-rules";
      destination = "/etc/udev/rules.d/40-streamdeck.rules";
      text = builtins.readFile opendeckUdev;
    })
  ];
}
