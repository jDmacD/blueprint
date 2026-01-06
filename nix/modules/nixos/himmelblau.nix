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

  services.himmelblau = {
    enable = lib.mkDefault true;
    settings = {
      # Replace with your actual domain
      domain = "heanet.ie";

      # Replace with your Entra ID group GUID(s)
      # Users must be members of these groups to authenticate
      pam_allow_groups = [
        "7d6a7292-46c5-4db3-9453-020fac531955" # HEAnet CLG Services Architecture Team
        "789ca450-f8d6-45a8-8549-0f92d102625f" # Heanet Staff
        "dcf9ebc8-cc26-44b4-88ca-b99e8ce06c28" # Heanet Staff Users SG
      ];

      # Local groups to add authenticated users to
      local_groups = [
        "wheel"
        "docker"
      ];
    };
  };

  environment.systemPackages = with inputs.himmelblau.packages.${pkgs.system} ;[
    himmelblau
    himmelblau-desktop
  ];
}
