{
  pkgs,
  perSystem,
  ...
}:
{
  programs.firefox = {
    enable = true;
    # Keep the legacy profile path (new default is XDG from stateVersion 26.05).
    configPath = ".mozilla/firefox";
    profiles = {
      default = {
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
  stylix.targets.firefox.profileNames = [ "default" ];

  # Declared explicitly because crann.thunar (nix/modules/nixos/desktop.nix)
  # now enables xdg.mimeApps, which makes home-manager fully own
  # mimeapps.list (a read-only nix-store symlink) instead of the mutable,
  # self-registered file browsers normally write into on first run —
  # without this, surface's existing "Firefox is my browser" default
  # (previously just a runtime self-registration) would silently disappear.
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "x-scheme-handler/chrome" = [ "firefox.desktop" ];
    "text/html" = [ "firefox.desktop" ];
    "application/xhtml+xml" = [ "firefox.desktop" ];
    "application/x-extension-htm" = [ "firefox.desktop" ];
    "application/x-extension-html" = [ "firefox.desktop" ];
    "application/x-extension-shtml" = [ "firefox.desktop" ];
    "application/x-extension-xhtml" = [ "firefox.desktop" ];
    "application/x-extension-xht" = [ "firefox.desktop" ];
  };
}
