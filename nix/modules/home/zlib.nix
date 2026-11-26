{
  config,
  ...
}:
# zlib (github.com/heartleo/zlib): Z-Library from the terminal and, through
# crann's `crann.ai-utils.mcp.zlib` (package `zlib-cli`), as Claude Code's
# `zlib` MCP server: a fallback for ebooks Chaptarr's torrent indexers
# don't find. Needs crann's ai-utils module imported (picard does).
#
# Login is declarative: sops holds the account's session cookies, and
# sops-nix renders them into ~/.config/zlib/session.json, the file
# `zlib login` would write. No password is stored or passed on a command
# line. The cookies stay valid until the account password changes.
#
# sops keys (nix/secrets/personal.yaml), from a one-off login through
# ZLIB_PROXY in a scratch HOME (`jq .cookies ~/.config/zlib/session.json`):
#   zlib/remix_userid
#   zlib/remix_userkey
let
  # Any domain `zlib doctor` reports healthy; mirrors get seized and change.
  # ZLIB_DOMAIN overrides it for one run.
  domain = "https://z-lib.gd";
  # gluetun's HTTP proxy (catalogue gluetun/, LoadBalancer
  # 192.168.178.245), so Z-Library sees the AirVPN exit, not the home IP.
  # Also carries zlib's metadata lookups and cover downloads.
  proxy = "http://gluetun.lan.jtec.xyz:8888";
in
{
  # The MCP server gets the proxy in its own environment, so it applies
  # whatever shell Claude Code started from. Kindle, WeRead and remote
  # history deletion stay off (crann's default); downloads are confined to
  # ~/Downloads, where chaptarr_import_file (jtec-mcp) picks them up.
  crann.ai-utils.mcp.zlib = {
    enable = true;
    inherit proxy;
  };

  home.packages = [ config.crann.ai-utils.mcp.zlib.package ];

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

  # For the CLI. Set in the environment, not ~/.config/zlib/.env: zlib's
  # own settings screens write that file, so leave it to them. Session
  # variables only reach login shells; the MCP server doesn't rely on them.
  home.sessionVariables = {
    ZLIB_PROXY = proxy;
    ZLIB_DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
    ZLIB_SEARCH_EXTENSIONS = "epub";
  };
}
