{
  bolt-launcher,
  makeWrapper,
  symlinkJoin,
}:

# Route Java Sound's clip and line output through ALSA's default device.
symlinkJoin {
  name = "bolt-launcher-with-audio";
  paths = [ bolt-launcher ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/bolt-launcher" \
      --set JAVA_TOOL_OPTIONS \
        "-Djavax.sound.sampled.Clip='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]' -Djavax.sound.sampled.SourceDataLine='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]'"
  '';
}
