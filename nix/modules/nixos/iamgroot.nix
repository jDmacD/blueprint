{ pkgs, perSystem, ... }:
{
  virtualisation.oci-containers.containers.iamgroot = {
    image = "iamgroot:latest";
    imageFile = perSystem.self.iamgroot;
  };
}
