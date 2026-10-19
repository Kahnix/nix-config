{
  coreutils,
  findutils,
  gnugrep,
  gnused,
  symlinkJoin,
  writeShellApplication,
}:

# STALKER GAMMA without Mod Organizer 2 at launch time: gamma-deploy hardlinks
# Anomaly + the enabled MO2 mods into one folder, gamma-direct is the Steam
# launch-option wrapper that starts the game from it.
let
  gamma-deploy = writeShellApplication {
    name = "gamma-deploy";
    runtimeInputs = [
      coreutils
      findutils
      gnugrep
      gnused
    ];
    text = builtins.readFile ./gamma-deploy.sh;
  };
  gamma-direct = writeShellApplication {
    name = "gamma-direct";
    runtimeInputs = [ gamma-deploy ];
    text = builtins.readFile ./gamma-direct.sh;
  };
in
symlinkJoin {
  name = "gamma-direct";
  paths = [
    gamma-deploy
    gamma-direct
  ];
}
