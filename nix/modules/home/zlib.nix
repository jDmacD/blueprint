{
  config,
  perSystem,
  ...
}:
# zlib (github.com/heartleo/zlib, nix/packages/zlib-cli): Z-Library from the
# terminal, a fallback for ebooks Chaptarr's torrent indexers don't find.
#
# Login is declarative: sops holds the account's session cookies, and
# sops-nix renders them into ~/.config/zlib/session.json, the file
# `zlib login` would write. No password is stored or passed on a command
# line. The cookies stay valid until the account password changes.
#
# sops keys (nix/secrets/personal.yaml), from a one-off login in a scratch
# HOME (`jq .cookies ~/.config/zlib/session.json`):
#   zlib/remix_userid
#   zlib/remix_userkey
let
  # Any domain `zlib doctor` reports healthy; mirrors get seized and change.
  # ZLIB_DOMAIN overrides it for one run.
  domain = "https://z-lib.gd";
in
{
  home.packages = [ perSystem.self.zlib-cli ];

  sops.secrets."zlib/remix_userid" = { };
  sops.secrets."zlib/remix_userkey" = { };

  sops.templates."zlib-session.json" = {
    path = "${config.home.homeDirectory}/.config/zlib/session.json";
    mode = "0600";
    content = builtins.toJSON {
      cookies = {
        remix_userid = config.sops.placeholder."zlib/remix_userid";
        remix_userkey = config.sops.placeholder."zlib/remix_userkey";
      };
      inherit domain;
      mode = "eapi";
    };
  };

  # Set in the environment, not ~/.config/zlib/.env: zlib's own settings
  # screens write that file, so leave it to them.
  home.sessionVariables = {
    ZLIB_DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
    ZLIB_SEARCH_EXTENSIONS = "epub";
  };
}
