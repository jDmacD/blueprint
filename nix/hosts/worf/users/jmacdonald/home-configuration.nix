{
  pkgs,
  config,
  osConfig,
  inputs,
  ...
}:
{

  imports =
    (with inputs.self.homeModules; [
      home-shared
      sops
      nix-utils
    ])
    ++ [
      inputs.crann.modules.homeManager.shells
      inputs.crann.modules.homeManager.terminal
    ];

  crann = {
    shells = {
      enable = true;
      flakeInspectPath = "${config.home.homeDirectory}/blueprint";
    };
    terminal = {
      enable = true;
      zellij.extraSettings = {
        web_server_ip = "0.0.0.0";
        web_server_port = 8082;
        web_server_cert = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/cert.pem";
        web_server_key = "/var/lib/acme/${osConfig.networking.hostName}.jtec.xyz/key.pem";
      };
    };
  };

  home.stateVersion = "25.11"; # initial home-manager state
}
