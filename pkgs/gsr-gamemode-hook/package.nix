{
  coreutils,
  systemd,
  writeShellApplication,
}:

# gamemode start/end hook: free the GPU from the replay buffer while a game
# runs. The marker restarts it on exit only if it was running before, so a
# buffer toggled off with Super+Alt+Shift+R stays off.
writeShellApplication {
  name = "gsr-gamemode-hook";
  # gamemoded's PATH holds only pkexec, so every tool must be listed here.
  runtimeInputs = [
    coreutils
    systemd
  ];
  text = builtins.readFile ./gsr-gamemode-hook.sh;
}
