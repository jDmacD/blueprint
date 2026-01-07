{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.himmelblau.nixosModules.himmelblau ];

  services = {
    xserver.enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };
  /*
  cat /etc/himmelblau/himmelblau.conf
  sudo systemctl restart himmelblaud.service && sudo systemctl restart himmelblaud-tasks.service 
  Test with:
  aad-tool auth-test --name 
  */

  services.himmelblau = {
    enable = lib.mkDefault true;
    settings = {
      # domain = "heanet.ie";
      domain = "jtec.xyz";
      apply_policy = true;
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
      # pam_allow_groups = [
      #   "7d6a7292-46c5-4db3-9453-020fac531955" # HEAnet CLG Services Architecture Team
      #   "789ca450-f8d6-45a8-8549-0f92d102625f" # Heanet Staff
      #   "dcf9ebc8-cc26-44b4-88ca-b99e8ce06c28" # Heanet Staff Users SG
      # ];
      pam_allow_groups = [
        "55f3aff4-8f5f-4aab-bdde-3cebfdb018a8"
        "ae84f46e-7ea6-4394-a9f2-8d82c0dea98a"
      ];

      # Local groups to add authenticated users to
      local_groups = [
        "wheel"
        "docker"
      ];
    };
  };

  environment.systemPackages = with inputs.himmelblau.packages.${pkgs.system}; [
    himmelblau
    himmelblau-desktop
  ];
}
