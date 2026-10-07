{
  gpu-screen-recorder,
  libnotify,
  systemd,
  writeShellApplication,
}:

# Replay-buffer control for gsr-replay.service: Hyprland binds call this instead
# of raw pkill, so save/toggle are idempotent and failures are reported.
writeShellApplication {
  name = "gsr-replay";
  runtimeInputs = [
    gpu-screen-recorder
    libnotify
    systemd
  ];
  text = builtins.readFile ./gsr-replay.sh;
}
