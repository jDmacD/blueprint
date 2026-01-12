{ pkgs, osConfig, ... }:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };
  programs.btop = {
    enable = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      kubernetes = {
        disabled = false;
      };
      localip = {
        ssh_only = false;
        disabled = false;
      };
      status = {
        disabled = false;
      };
    };
  };
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false;
    settings = {
      web_server_ip = "0.0.0.0";
      web_server_port = 8082;
      web_server_cert = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/cert.pem";
      web_server_key = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/key.pem";
    };
  };

}
