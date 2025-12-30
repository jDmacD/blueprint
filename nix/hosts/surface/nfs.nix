{
  ...
}:
{
  fileSystems."/mnt/calibre-library" = {
    device = "picard.lan:/calibre-library";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };

  fileSystems."/spinner" = {
    device = "picard.lan:/spinner";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };
}