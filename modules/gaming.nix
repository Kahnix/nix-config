{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    bolt-launcher
    lutris
    mangohud
    prismlauncher
    protonup-qt
    wineWow64Packages.staging
    winetricks
  ];
}
