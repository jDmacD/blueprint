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

  fileSystems."/export/calibre-library" = {
    device = "/mnt/calibre-library";
    options = [ "bind" ];
  };
  
  fileSystems."/export/spinner" = {
    device = "/spinner";
    options = [ "bind" ];
  };
}