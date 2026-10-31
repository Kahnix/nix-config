{ makeWrapper, symlinkJoin }:

# Java Sound picks the first hardware PCM for clips and lines, and card 0 here
# is snd-aloop (WO-Mic's loopback), so game audio vanishes into it. Point both
# at ALSA's `default` device, which goes through PipeWire. The variable is
# inherited by the JVMs the launcher spawns (RuneLite).
package: mainProgram:
symlinkJoin {
  name = "${package.pname or package.name}-alsa-default";
  paths = [ package ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/${mainProgram}" \
      --set JAVA_TOOL_OPTIONS \
        "-Djavax.sound.sampled.Clip='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]' -Djavax.sound.sampled.SourceDataLine='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]'"
  '';
}
