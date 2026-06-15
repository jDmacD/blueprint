{ pkgs, ... }:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl --instance 0";
  sunshine-do = pkgs.writeShellScriptBin "do" ''
    # Configure the virtual display (DP-2) with client resolution
    ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-2,''${1}x''${2}@''${3},auto,1
    # Optionally disable your physical monitor during streaming
    ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-1,disable
  '';
  sunshine-undo = pkgs.writeShellScriptBin "undo" ''
    ${pkgs.hyprland}/bin/hyprctl reload
  '';
  sunshine-dune = pkgs.writeShellScriptBin "dune" ''
    setsid steam steam://rungameid/1689500
  '';
in
{
  hardware.display = {
    edid = {
      enable = true;
      
      # Option 1: Use a pre-generated EDID file
      packages = [
        (pkgs.runCommand "edid-virtual-display" {} ''
          mkdir -p "$out/lib/firmware/edid"
          cp ${./virtual-display.bin} "$out/lib/firmware/edid/virtual-display.bin"
        '')
      ];
      
      # Option 2: OR generate from modeline (simpler but less control)
      # modelines = {
      #   "Virtual4K" = "594.00   3840 4016 4104 4400   2160 2168 2178 2250   +hsync +vsync";
      #   "Virtual1440p" = "241.50   2560 2608 2640 2720   1440 1443 1448 1481   -hsync +vsync";
      # };
    };
    
    # Configure the virtual output
    outputs."DP-2" = {
      edid = "virtual-display.bin";  # or "Virtual4K.bin" if using modelines
      mode = "e";  # Force enable even with nothing connected
    };
  };
  services.sunshine = {
    enable = true;
    autoStart = true;
    # capSysAdmin = true;
    openFirewall = true;
    settings = {
      capture = "wlr";
      adapter_name = "/dev/dri/renderD128";
      encoder = "nvenc";
      output_name = "DP-2";
    };
    # https://gist.github.com/Dregu/4c0dbb2582835e5d95e06c4bf7624e3b`
    applications = {
      apps = [
        {
          name = "Steam Big Picture";
          prep-cmd = [
            {
              do = ''${sunshine-do}/bin/do "''${SUNSHINE_CLIENT_WIDTH}" "''${SUNSHINE_CLIENT_HEIGHT}" "''${SUNSHINE_CLIENT_FPS}"'';
              undo = "${sunshine-undo}/bin/undo";
            }
          ];
          detached = [ "setsid steam steam://open/bigpicture" ];
          auto-detach = "true";
          wait-all = "true";
          exit-timeout = "5";
        }
        {
          name = "Virtual Display";
          prep-cmd = [
            {
              do = ''${sunshine-do}/bin/do "''${SUNSHINE_CLIENT_WIDTH}" "''${SUNSHINE_CLIENT_HEIGHT}" "''${SUNSHINE_CLIENT_FPS}"'';
              undo = "${sunshine-undo}/bin/undo";
            }
          ];
        }
        {
          name = "Dune";
          prep-cmd = [
            {
              do = ''${sunshine-do}/bin/do "''${SUNSHINE_CLIENT_WIDTH}" "''${SUNSHINE_CLIENT_HEIGHT}" "''${SUNSHINE_CLIENT_FPS}"'';
              undo = "${sunshine-undo}/bin/undo";
            }
          ];
          detached = [ "${sunshine-dune}/bin/dune" ];
          auto-detach = "true";
          wait-all = "true";
          exit-timeout = "5";
          image-path = "~/.local/share/icons/hicolor/256x256/apps/steam_icon_1689500.png";
        }
      ];

    };
  };

}
