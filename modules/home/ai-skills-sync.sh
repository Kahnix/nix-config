# Mirror the canonical skill tree into the directories that Claude Code and
# Antigravity read. Zed and OpenCode read ~/.agents/skills directly, so they
# need no links. Run by Home Manager after each switch, and available as
# `ai-skills-sync` for skills added between rebuilds.
#
# Usage: ai-skills-sync [home]
home="${1:-$HOME}"
root="$home/.agents/skills"
targets=(
  "$home/.claude/skills"
  "$home/.gemini/config/skills"
)

if [ ! -d "$root" ]; then
  echo "ai-skills-sync: $root does not exist, nothing to link" >&2
  exit 0
fi

for target in "${targets[@]}"; do
  mkdir -p "$target"

  for src in "$root"/*; do
    [ -d "$src" ] || continue
    name="$(basename "$src")"
    dest="$target/$name"
    if [ -L "$dest" ]; then
      ln -sfn "$src" "$dest"
    elif [ -e "$dest" ]; then
      # A real directory from an older install; leave it for a human to move.
      echo "ai-skills-sync: $dest is not a symlink, leaving it alone" >&2
    else
      ln -s "$src" "$dest"
    fi
  done

  # Drop links whose skill was removed from the canonical tree.
  for dest in "$target"/*; do
    [ -L "$dest" ] || continue
    case "$(readlink "$dest")" in
      "$root"/*) [ -e "$dest" ] || rm -f "$dest" ;;
    esac
  done
done
