{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  /*
    Helper to build VSCode extensions with platform-specific overrides.

    This function merges configuration attributes BEFORE building the derivation,
    not after. Attempting to merge with // or lib.recursiveUpdate AFTER calling
    buildVscodeMarketplaceExtension doesn't work because derivations are immutable -
    the merge only changes external attributes, not the actual build specification.

    Usage: mkExtension baseConfig darwinOverrides
      baseConfig: Base configuration (typically Linux defaults)
      darwinOverrides: Overrides to apply on Darwin (merged recursively)

    On Darwin: recursiveUpdate merges the overrides into base, then builds
    On Linux: darwinOverrides is ignored, builds with base config only
  */
  mkExtension =
    base: darwinOverrides:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension (
      lib.recursiveUpdate base (lib.optionalAttrs pkgs.stdenv.isDarwin darwinOverrides)
    );
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
          gitlab.keybindingHints.enabled = false;
          gitlab.duoChat.enabled = false;
          gitlab.duoCodeSuggestions.enabled = false;
          gitlab.duoAgentPlatform.enabled = false;
          gitlab.duo.enabledWithoutGitlabProject = false;
          gitlab.duoCodeSuggestions.openTabsContext = false;
          chat.agent.enabled = false;
          chat.disableAIFeatures = true;
          chat.showAgentSessionsViewDescription = false;
          terminal.integrated.initialHint = false;
          sops.defaults.ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        };
        extensions =
          with pkgs.vscode-extensions;
          [
            ms-vscode-remote.remote-ssh
            charliermarsh.ruff
            ms-python.python
            bbenoist.nix
            jnoortheen.nix-ide
            ms-azuretools.vscode-docker
            mechatroner.rainbow-csv
            signageos.signageos-vscode-sops
            # anthropic.claude-code
            /*
              Continue extension requires platform-specific builds:
              - Linux: needs autoPatchelfHook to patch ELF binaries
              - Darwin: uses native Mach-O binaries, no patching needed
            */
          ]
          ++ [
            (mkExtension
              {
                mktplcRef = {
                  name = "continue";
                  publisher = "Continue";
                  version = "0.9.256";
                  sha256 = "sha256-oe6dF0pdodtEl963Z3czHOrLnzWH/ROGIZ+I+r0pV1o=";
                  arch = "linux-x64";
                };
                nativeBuildInputs = [ pkgs.autoPatchelfHook ];
                buildInputs = [ pkgs.stdenv.cc.cc.lib ];
              }
              {
                # Darwin overrides: different arch, no ELF patching
                mktplcRef.arch = "aarch64-darwin";
                nativeBuildInputs = [ ];
                buildInputs = [ ];
              }
            )
            (mkExtension
              {
                mktplcRef = {
                  name = "claude-code";
                  publisher = "anthropic";
                  version = "2.1.1";
                  sha256 = "sha256-SSVmSVthYpW8lSCSdHHFJiXagx4QzhhNsJYo7F5XGbA=";
                  arch = "linux-x64";
                };
                nativeBuildInputs = [ ];
                buildInputs = [ ];
              }
              {
                # Darwin overrides: different arch, no ELF patching
                mktplcRef.arch = "aarch64-darwin";
                nativeBuildInputs = [ ];
                buildInputs = [ ];
              }
            )
          ]
          ++ (pkgs.lib.optionals (osConfig.networking.hostName == "lwh-hotapril") [
            gitlab.gitlab-workflow
            hashicorp.terraform
          ]);
      };
    };
    mutableExtensionsDir = false;
  };
}
