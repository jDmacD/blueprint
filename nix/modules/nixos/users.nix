{ pkgs, ... }:
{

  users.users = {
    jmacdonald = {
      isNormalUser = true;
      initialPassword = "password";
      openssh.authorizedKeys.keys = [];
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "sound"
        "video"
        "docker"
      ];
      packages = [ ];
    };
    awilson = {
      isNormalUser = true;
      initialPassword = "password";
      openssh.authorizedKeys.keys = [];
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "sound"
        "video"
        "docker"
      ];
      packages = [ ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
  nixpkgs.config.allowUnfree = true;
}
