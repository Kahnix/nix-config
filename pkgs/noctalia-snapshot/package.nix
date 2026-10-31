{
  python3Packages,
  writers,
}:

# `noctalia-snapshot [NIX_CONFIG_DIR]`: fold Noctalia settings-UI changes into
# modules/desktop/noctalia/settings.toml. Uses the `noctalia` on PATH to
# validate, so it matches the running shell.
writers.writePython3Bin "noctalia-snapshot" {
  libraries = [ python3Packages.tomlkit ];
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./noctalia-snapshot.py)
