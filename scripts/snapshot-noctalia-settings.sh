#!/usr/bin/env bash
# Freeze the live noctalia shell settings into the repo.
#
# noctalia's settings menu edits ~/.config/noctalia/config.toml directly at
# runtime; home-manager never manages that file (see programs.noctalia in
# home/$USER/linux-desktop.nix). Run this after tuning things in the
# noctalia settings UI to commit the new baseline, so `home-manager switch`
# reproduces it on other rebuilds/machines.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$repo_root/home/$USER/noctalia-settings.toml"

noctalia config export merged > "$dest"
noctalia config validate "$dest"

echo "Wrote $dest"
echo "Review with: git -C '$repo_root' diff -- home/$USER/noctalia-settings.toml"
