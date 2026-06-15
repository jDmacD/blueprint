{
  pkgs,
  inputs,
  ...
}:
{

  imports =
    [ ]
    ++ (with inputs.self.homeModules; [
      hyprland-sunshine
    ]);

  home.packages = with pkgs; [
  ];

  home.stateVersion = "25.11";
}
