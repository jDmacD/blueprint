{ pkgs, inputs, ... }:
{

  imports = with inputs.self.nixosModules; [
    stylix
    hyprland
    peripherals
    fonts
  ];

  hardware = {
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
      package = pkgs.bluez;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
  };

  services = {
    upower = {
      enable = true;
    };
    blueman = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    # Doesn't work with wayland / hyrland
    kmscon = {
      enable = false;
    };
  };
}
