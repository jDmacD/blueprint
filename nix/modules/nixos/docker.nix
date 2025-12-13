{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.oci-containers.backend = "docker";
}
