{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    dnsutils
    iperf
    ipcalc
  ];

}
