{
  pkgs,
  perSystem,
  ...
}:
{
  programs.firefox = {
    enable = true;
    profiles = {
      jmacdonald = {
        extensions = {
          force = true;
          packages = with perSystem.nur.repos.rycee.firefox-addons; [
            bitwarden
          ];
        };
        settings = {
          "signon.rememberSignons" = false;
          "browser.startup.homepage" = "https://search.jtec.xyz";
        };

        search = {
          force = true;
          default = "Searx";
          order = [
            "searx"
            "google"
          ];
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            "Searx" = {
              urls = [ { template = "https://search.jtec.xyz/?q={searchTerms}"; } ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@searx" ];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Nix sites";
              toolbar = true;
              bookmarks = [
              ];
            }
          ];
        };
      };
    };
  };
  stylix.targets.firefox.profileNames = [ "jmacdonald" ];
}
