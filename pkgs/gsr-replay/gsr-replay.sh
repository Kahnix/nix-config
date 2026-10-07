sock="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/gsr.sock"

# A missing notification daemon must not swallow the result.
note() { notify-send "$@" || true; }

case "${1:-save}" in
  save)
    seconds="${2:-60}"
    if path=$(gsr-cli -ipc "$sock" save-replay "$seconds"); then
      note "Replay saved" "$(basename "$path")"
      printf '%s\n' "$path"
    else
      note --urgency=critical "Replay buffer is not running" \
        "The last ${seconds}s were not saved."
      exit 1
    fi
    ;;
  toggle)
    if gsr-cli -ipc "$sock" status >/dev/null 2>&1; then
      systemctl --user stop gsr-replay.service
      note "Replay buffer stopped"
    else
      systemctl --user start gsr-replay.service
      note "Replay buffer started"
    fi
    ;;
  *)
    echo "usage: gsr-replay [save [seconds] | toggle]" >&2
    exit 2
    ;;
esac
