{ pkgs, ... }:
{

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      open = false;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };

  # https://discourse.nixos.org/t/nvidia-drm-kernel-driver-nvidia-drm-in-use-nvk-requires-nouveau/46124
  environment.variables = {
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  };
}
