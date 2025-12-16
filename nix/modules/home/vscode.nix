{
  pkgs,
  config,
  osConfig,
  ...
}:
let
  nativeBuildInputs =
    if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then [ ] else [ pkgs.autoPatchelfHook ];
in
{

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles = {
      default = {
        userSettings = {
          terminal.integrated.fontFamily = "Symbols Nerd Font Mono";
          workbench.colorTheme = "Stylix";
          git.autofetch = true;
          git.confirmSync = false;
          sqltools.useNodeRuntime = false;
          gitlab.duoChat.enabled = false;
          gitlab.duoCodeSuggestions.enabled = false;
          chat.agent.enabled = false;
          chat.showAgentSessionsViewDescription = false;
          sops.defaults.ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        };
        extensions = [
          pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
          pkgs.vscode-extensions.charliermarsh.ruff
          pkgs.vscode-extensions.ms-python.python
          pkgs.vscode-extensions.bbenoist.nix
          pkgs.vscode-extensions.jnoortheen.nix-ide
          pkgs.vscode-extensions.ms-azuretools.vscode-docker
          pkgs.vscode-extensions.mechatroner.rainbow-csv
          pkgs.vscode-extensions.signageos.signageos-vscode-sops
          (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
            mktplcRef = {
              name = "continue";
              publisher = "Continue";
              version = "0.9.256";
              sha256 = "sha256-+/0ZQkRS6AD8u5+t2hiPwQxzwhEc+n2F0GVk1s0n74U=";
              arch = "${pkgs.stdenv.hostPlatform.system}";
            };
            nativeBuildInputs = nativeBuildInputs;
            buildInputs = [ pkgs.stdenv.cc.cc.lib ];
          })
        ];
      };
    };
    mutableExtensionsDir = false;
  };
}
