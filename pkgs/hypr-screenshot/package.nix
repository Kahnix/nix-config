{ hyprshot, writeShellApplication }:

# `hypr-screenshot region|window|output`: capture, copy, and save to
# ~/Pictures/Screenshots.
writeShellApplication {
  name = "hypr-screenshot";
  runtimeInputs = [ hyprshot ];
  text = builtins.readFile ./hypr-screenshot.sh;
}
