{ hyprland, writeShellApplication }:

# `stream-display-mode WxH@Hz`: switch the desktop monitor's mode for a
# Moonlight session (Sunshine prep-cmd do/undo).
writeShellApplication {
  name = "stream-display-mode";
  runtimeInputs = [ hyprland ];
  text = builtins.readFile ./stream-display-mode.sh;
}
