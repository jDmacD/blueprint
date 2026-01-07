{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{

  imports = [
    inputs.self.darwinModules.host-shared
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
