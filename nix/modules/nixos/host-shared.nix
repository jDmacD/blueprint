{
  pkgs,
  inputs,
  ...
}:
{

  imports = [
    inputs.self.darwinModules.host-shared
  ];

  environment.systemPackages = with pkgs; [
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
}
