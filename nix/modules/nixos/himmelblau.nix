{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.himmelblau;

  domainPresets = {
    heanet = {
      domain = ["heanet.ie"];
      apply_policy = false;
      # Use comma-separated string instead of list - himmelblau expects commas, not spaces
      pam_allow_groups = [
        "7d6a7292-46c5-4db3-9453-020fac531955"
        "789ca450-f8d6-45a8-8549-0f92d102625f"
        "dcf9ebc8-cc26-44b4-88ca-b99e8ce06c28"
      ];
    };
    jtec = {
      domain = ["jtec.xyz"];
      apply_policy = false;
      # Use comma-separated string instead of list - himmelblau expects commas, not spaces
      pam_allow_groups = [ "55f3aff4-8f5f-4aab-bdde-3cebfdb018a8" "ae84f46e-7ea6-4394-a9f2-8d82c0dea98a" ];
    };
  };

  presetConfig = domainPresets.${cfg.domainPreset};
in
{
  imports = [ inputs.himmelblau.nixosModules.himmelblau ];

  options.services.himmelblau = {
    domainPreset = lib.mkOption {
      type = lib.types.enum [
        "heanet"
        "jtec"
      ];
      default = "jtec";
      description = "Which domain preset to use for himmelblau configuration";
    };
  };

  config = {
    # services = {
    #   xserver.enable = true;
    #   desktopManager.gnome.enable = true;
    #   displayManager.gdm.enable = true;
    # };
    /*
      cat /etc/himmelblau/himmelblau.conf
      sudo systemctl restart himmelblaud.service && sudo systemctl restart himmelblaud-tasks.service
      Test with:
      aad-tool auth-test --name
    */

    # Failed to set up mount namespacing: /var/cache/nss-himmelblau: No such file or directory
    systemd.tmpfiles.rules = [
      "d /var/cache/nss-himmelblau 0755 root root -"
    ];
    services.himmelblau = {
      enable = lib.mkDefault true;
      pamServices = [
        "passwd"
        "login"
        "systemd-user"
      ];
      settings = {
        domain = presetConfig.domain;
        apply_policy = presetConfig.apply_policy;
        hello_pin_min_length = 4;
        # NOTE: home_attr defaults to "UUID" and home_alias defaults to "SPN"
        # This creates separate home directories for Azure AD users like /home/jmacdonald@jtec.xyz
        # This allows coexistence with local users that may have /home/jmacdonald
        # If you want Azure AD users to use /home/<username> instead, set:
        #   home_attr = "CN";
        #   home_alias = "CN";
        /*
          cli:
          ---------------------------------
          PAM_IGNORE, unexpected resolver response err=Error
          PAM_IGNORE: An unexpected error occurred.
          If you are now prompted for a password from pam_unix, please disregard the prompt, go back and try again.

          logs:
          journalctl -u himmelblaud.service
          ---------------------------------
          Failed fetching Intune service endpoints: RequestFailed("403 Forbidden")q
        */
        debug = true;
        pam_allow_groups = presetConfig.pam_allow_groups;

        # Local groups to add authenticated users to
        local_groups = [
          "wheel"
          "docker"
        ];
      };
    };

    environment.systemPackages = with inputs.himmelblau.packages.${pkgs.stdenv.hostPlatform.system}; [
      himmelblau
      himmelblau-desktop
    ];
  };
}
