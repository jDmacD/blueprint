{
  ...
}:
{
  services = {
    nfs = {
      server = {
        enable = true;
        exports = ''
          /export *(rw,fsid=0,no_subtree_check)
          /export/calibre-library *(rw,insecure,no_subtree_check)
          /export/spinner  *(rw,insecure,no_subtree_check)
        '';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/calibre-library 0755 root root - -"
  ];

  fileSystems."/export/calibre-library" = {
    device = "/var/lib/calibre-library";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/export/spinner" = {
    device = "/spinner";
    fsType = "none";
    options = [ "bind" ];
  };
}
