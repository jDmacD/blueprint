{
  perSystem,
  ...
}:
{
  programs.firefox = {
    enable = true;
    profiles = {
      jmacdonald = {
        extensions = {
          packages = with perSystem.nur.repos.rycee.firefox-addons; [
            bitwarden
          ];
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Nix sites";
              toolbar = true;
              bookmarks = [
                {
                  name = "Home Manager Options";
                  url = "https://home-manager-options.extranix.com/?query=&release=release-25.11";
                }
                {
                  name = "Stylix";
                  url = "https://nix-community.github.io/stylix/";
                }
                {
                  name = "NixOS Packages";
                  url = "https://search.nixos.org/packages?channel=25.11&query=";
                }
                {
                  name = "Numtide Blueprint";
                  url = "https://numtide.github.io/blueprint/main/";
                }
              ];
            }
          ];
        };
      };
    };
  };
  stylix.targets.firefox.profileNames = [ "jmacdonald" ];
}
