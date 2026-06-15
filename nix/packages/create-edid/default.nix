{ pkgs }:
pkgs.writers.writePython3Bin "create-edid" { } (builtins.readFile ./app.py)
