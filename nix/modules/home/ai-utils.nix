{
  pkgs,
  config,
  perSystem,
  ...
}:
{
  sops = {
    secrets.mcp_env = {
      path = "%r/mcp.env";
    };
  };
  programs.claude-code = {
    enable = true;
    mcpServers = {
      steampipe = {
        type = "stdio";
        command = "${perSystem.self.mcp-steampipe}/bin/steampipe-mcp-wrapper";
      };
      argocd = {
        type = "stdio";
        command = "${perSystem.self.mcp-argocd}/bin/argocd-mcp-wrapper";
      };
      grafana = {
        type = "stdio";
        command = "${perSystem.self.mcp-grafana}/bin/grafana-mcp-wrapper";
      };
      gitlab = {
        type = "stdio";
        command = "${perSystem.self.mcp-gitlab}/bin/gitlab-mcp-wrapper";
      };
    };
  };
}
