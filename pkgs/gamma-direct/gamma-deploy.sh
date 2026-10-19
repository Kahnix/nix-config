# Builds a ready-to-run STALKER GAMMA folder without Mod Organizer 2: Anomaly
# plus every mod enabled in the MO2 profile, applied in MO2's priority order,
# plus MO2's overwrite folder on top. Everything is hardlinked (no extra disk
# space), so an in-game edit of a mod file (MCM settings) lands in the mod
# itself, as it does through MO2. appdata (saves, user.ltx, logs) is shared
# with the plain Anomaly install, so both launch paths see the same game.
#
# MO2's virtual file system (usvfs) costs ~70 s of every launch under Wine;
# this folder needs none of it. Re-run after changing mods in MO2.

root="${GAMMA_ROOT:-/mnt/storage/Games/STALKER}"
anomaly="$root/Anomaly"
gamma="$root/GAMMA"
play="$root/Play"
modlist="$gamma/profiles/G.A.M.M.A/modlist.txt"
staging="$play.new"

for path in "$anomaly/bin" "$gamma/mods" "$modlist"; do
  [ -e "$path" ] || { echo "gamma-deploy: $path not found" >&2; exit 1; }
done

rm -rf "$staging"
mkdir -p "$staging"

# Base game, minus appdata (shared instead of copied).
find "$anomaly" -mindepth 1 -maxdepth 1 ! -name appdata -exec cp -al {} "$staging/" \;
ln -s "$anomaly/appdata" "$staging/appdata"

# modlist.txt lists the highest priority first: apply bottom-up so higher
# priority mods replace lower ones. Lines: +enabled, -disabled; separators are
# "<name>_separator"; the file has Windows line endings.
count=0
while IFS= read -r mod; do
  dir="$gamma/mods/$mod"
  [ -d "$dir" ] || { echo "gamma-deploy: enabled mod missing: $mod" >&2; exit 1; }
  for entry in "$dir"/* "$dir"/.[!.]*; do
    [ -e "$entry" ] || continue
    case "${entry##*/}" in
      meta.ini) ;;
      # Presets that belong in the shared appdata; never replace existing ones.
      appdata) cp -al --update=none "$entry/." "$anomaly/appdata/" ;;
      *) cp -al --remove-destination "$entry" "$staging/" ;;
    esac
  done
  count=$((count + 1))
done < <(tr -d '\r' < "$modlist" | grep '^+' | sed 's/^+//' | grep -v '_separator$' | tac)

cp -al --remove-destination "$gamma/overwrite/." "$staging/"

# Swap in the new folder; removing the old one only drops hardlinks.
if [ -e "$play" ]; then
  mv "$play" "$play.old"
fi
mv "$staging" "$play"
rm -rf "$play.old"
touch "$play/.gamma-deploy-stamp"

echo "gamma-deploy: $count mods deployed to $play"
