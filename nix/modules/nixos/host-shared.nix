{
  pkgs,
  lib,
  ...
}:
{
  # Shared Nix configuration
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # jdmacd: crann CI pushes its test hosts (niri, noctalia, claude-code,
      # ...) built against crann's nixpkgs, which blueprint's nixpkgs follows,
      # so those builds match here. Also holds the patched Pi kernels.
      # numtide: llm-agents (claude-code). Declared here rather than relying on
      # the flakes' nixConfig, which Nix ignores (accept-flake-config = false).
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        "https://jdmacd.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "jdmacd.cachix.org-1:0DcSfXShBIng2EbPW44fxoXjXowKhZZWrbYqcozFhfM="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };

    extraOptions = ''
      # Ensure we can still build when missing-server is not accessible
      fallback = true
    '';
  };

  time.timeZone = lib.mkDefault "Europe/Dublin";

  environment.systemPackages = with pkgs; [
    git
    waypipe
  ];

  /*
    This is for checking and updating firmware
    fwupdmgr refresh
    fwupdmgr get-updates
    fwupdmgr update
  */
  services = {
    udisks2.enable = true;
    fwupd.enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };
}
