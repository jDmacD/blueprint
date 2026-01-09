{
  pkgs,
  config,
  perSystem,
  ...
}:
{
  sops = {
    secrets.steampipe_yml = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.config/steampipe/steampipe.yaml";
    };
  };
  programs.claude-code = {
    enable = true;
    mcpServers = {
      steampipe = {
        type = "stdio";
        command = "${perSystem.self.steampipe}/bin/steampipe-mcp-wrapper";
      };
    };
  };
}
