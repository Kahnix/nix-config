"""Fold Noctalia settings-UI changes back into the repo.

The settings UI writes overrides to $XDG_STATE_HOME/noctalia/settings.toml.
This merges them into modules/desktop/noctalia/settings.toml, keeping its
comments, and skips keys Nix sets elsewhere (Stylix palette/fonts/opacity,
wallpaper paths from noctalia.nix): those are the keys in the generated
~/.config/noctalia/config.toml that settings.toml does not define.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

import tomlkit

REL = "modules/desktop/noctalia/settings.toml"


def flat(table, prefix=()):
    for key, value in table.items():
        if isinstance(value, dict):
            yield from flat(value, prefix + (key,))
        else:
            yield prefix + (key,), value


def main():
    repo = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / "nix-config")
    dest = repo / REL
    state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    overrides_path = state_home / "noctalia/settings.toml"
    generated_path = config_home / "noctalia/config.toml"

    if not dest.is_file():
        sys.exit(f"{dest} not found; pass the nix-config checkout as the argument")
    if not overrides_path.is_file():
        print(f"No settings-UI changes ({overrides_path} does not exist).")
        return

    doc = tomlkit.parse(dest.read_text())
    overrides = tomlkit.parse(overrides_path.read_text()).unwrap()
    repo_keys = {path for path, _ in flat(doc.unwrap())}
    nix_owned = {path for path, _ in flat(tomlkit.parse(generated_path.read_text()).unwrap())} - repo_keys

    # The state file's own bookkeeping, not a setting.
    overrides.pop("config_version", None)

    changed, skipped = [], []
    for path, value in flat(overrides):
        name = ".".join(path)
        if path in nix_owned:
            skipped.append(name)
            continue
        table = doc
        for key in path[:-1]:
            if key not in table:
                table[key] = tomlkit.table()
            table = table[key]
        if table.get(path[-1]) != value:
            table[path[-1]] = value
            changed.append(name)

    if not changed:
        print("settings.toml already has every settings-UI change.")
    else:
        text = tomlkit.dumps(doc)
        with tempfile.NamedTemporaryFile("w", suffix=".toml") as tmp:
            tmp.write(text)
            tmp.flush()
            subprocess.run(["noctalia", "config", "validate", tmp.name], check=True)
        dest.write_text(text)
        print(f"Updated {dest}:")
        for name in changed:
            print(f"  {name}")
    if skipped:
        print("Skipped (set by Nix/Stylix, change them there):")
        for name in skipped:
            print(f"  {name}")
    print(f"Review: git -C {repo} diff -- {REL}")


main()
