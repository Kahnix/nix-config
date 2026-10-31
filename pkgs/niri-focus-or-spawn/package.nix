{
  jq,
  niri,
  writeShellApplication,
}:

# `niri-focus-or-spawn APP_ID COMMAND...`: focus the first window with APP_ID,
# or run COMMAND when there is none.
writeShellApplication {
  name = "niri-focus-or-spawn";
  runtimeInputs = [
    jq
    niri
  ];
  text = builtins.readFile ./niri-focus-or-spawn.sh;
}
