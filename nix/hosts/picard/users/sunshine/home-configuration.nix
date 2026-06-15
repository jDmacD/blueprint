{
  pkgs,
  inputs,
  ...
}:
{

  imports =
    [ ]
    ++ (with inputs.self.homeModules; [
    ]);

  home.packages = with pkgs; [
  ];

  home.stateVersion = "25.11";
}
