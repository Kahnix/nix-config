{ makeWrapper, symlinkJoin }:

# Java Sound picks the first hardware PCM for clips and lines, and card 0 here
# is snd-aloop (WO-Mic's loopback), so game audio vanishes into it. Point both
# at ALSA's `default` device, which goes through PipeWire. PipeWire's ALSA
# plugin names that device `alsa_playback.<exe>` from /proc/self/exe (`java`
# for Bolt, `RuneLite` for Jagex Launcher's embedded-JVM AppImage).
package: mainProgram: jvmExe:
symlinkJoin {
  name = "${package.pname or package.name}-alsa-default";
  paths = [ package ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/${mainProgram}" \
      --set JAVA_TOOL_OPTIONS \
        "-Djavax.sound.sampled.Clip='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.${jvmExe} [default]' -Djavax.sound.sampled.SourceDataLine='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.${jvmExe} [default]'"
  '';
}
