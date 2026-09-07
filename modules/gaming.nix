{ pkgs, ... }:
let
  boltLauncher = pkgs.symlinkJoin {
    name = "bolt-launcher-with-audio";
    paths = [ pkgs.bolt-launcher ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/bolt-launcher" \
        --set JAVA_TOOL_OPTIONS \
          "-Djavax.sound.sampled.Clip='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]' -Djavax.sound.sampled.SourceDataLine='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]'"
    '';
  };
in
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
    boltLauncher
    lutris
    mangohud
    prismlauncher
    protonup-qt
    wineWow64Packages.staging
    winetricks
  ];
}
