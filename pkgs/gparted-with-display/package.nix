{
  coreutils,
  gparted,
  runCommand,
  writeShellApplication,
}:

# GParted's launcher elevates through pkexec, which scrubs the environment, so
# DISPLAY is gone by the time the root process tries to open its window. Elevate
# here instead, with DISPLAY re-exported inside the elevated command.
#
# This wraps the prebuilt gparted rather than patching gparted.in: an
# overrideAttrs patch rebuilds gparted from source on every nixpkgs bump.
let
  launcher = writeShellApplication {
    name = "gparted";
    runtimeInputs = [ coreutils ];
    text = ''
      if [ "$(id -u)" -eq 0 ]; then
        exec ${gparted}/bin/gparted "$@"
      fi
      exec pkexec --disable-internal-agent env DISPLAY="$DISPLAY" ${gparted}/bin/gparted "$@"
    '';
  };
in
runCommand "gparted-with-display" { } ''
  mkdir -p $out
  cp -rs ${gparted}/. $out/
  # cp copied the store's read-only directory modes; files stay symlinks.
  find $out -type d -exec chmod u+w {} +
  rm -f $out/bin/gparted $out/share/applications/gparted.desktop
  install -m755 ${launcher}/bin/gparted $out/bin/gparted
  install -m644 ${gparted}/share/applications/gparted.desktop $out/share/applications/gparted.desktop
  substituteInPlace $out/share/applications/gparted.desktop \
    --replace-fail "${gparted}/bin/gparted" "$out/bin/gparted"
''
