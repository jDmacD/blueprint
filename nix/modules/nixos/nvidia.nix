{ pkgs, config, ... }:
{

  environment.systemPackages = with pkgs; [
    nvitop
  ];
  services = {
    xserver = {
      enable = false;
      videoDrivers = [ "nvidia" ];
    };
  };
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

  # Pin Vulkan to the NVIDIA driver so Mesa's NVK doesn't complain:
  # https://discourse.nixos.org/t/nvidia-drm-kernel-driver-nvidia-drm-in-use-nvk-requires-nouveau/46124
  # VK_DRIVER_FILES replaces the loader's whole driver list, so a path that
  # doesn't exist leaves Vulkan with no driver at all. The 595 driver ships its
  # manifest as nvidia_icd.json (it used to be nvidia_icd.x86_64.json); list the
  # 32-bit one too for Steam's 32-bit games.
  environment.variables = {
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.json";
  };
}
