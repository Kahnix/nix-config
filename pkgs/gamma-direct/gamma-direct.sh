# Steam launch-option wrapper for the STALKER GAMMA shortcut, whose target is
# MO2's ModOrganizer.exe: `gamma-direct %command%`. Starts the game from the
# deployed folder (gamma-deploy) instead, the way MO2's "Anomaly (DX11-AVX)"
# entry does: working directory bin/, SteamAppId 41700 (xrRazom's Steam
# sessions run as Call of Pripyat). Redeploys first when the MO2 mod list or
# mod set changed since the last deploy.

root="${GAMMA_ROOT:-/mnt/storage/Games/STALKER}"
play="$root/Play"
stamp="$play/.gamma-deploy-stamp"
gamma="$root/GAMMA"

if [ ! -e "$stamp" ] ||
  [ "$gamma/profiles/G.A.M.M.A/modlist.txt" -nt "$stamp" ] ||
  [ "$gamma/mods" -nt "$stamp" ] ||
  [ "$gamma/overwrite" -nt "$stamp" ]; then
  gamma-deploy
fi

args=()
for arg in "$@"; do
  case "$arg" in
    *ModOrganizer.exe) args+=("$play/bin/AnomalyDX11AVX.exe") ;;
    *) args+=("$arg") ;;
  esac
done

export SteamAppId=41700 SteamGameId=41700
cd "$play/bin"
exec "${args[@]}"
