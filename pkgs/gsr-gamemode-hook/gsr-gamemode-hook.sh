marker="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/gsr-paused-by-gamemode"
case "${1:-}" in
  # --no-block: gpu-screen-recorder can take until systemd's stop timeout
  # to exit, and gamemode kills hook scripts that outlive its timeout.
  start)
    if systemctl --user is-active --quiet gsr-replay.service; then
      systemctl --user stop --no-block gsr-replay.service
      touch "$marker"
    fi
    ;;
  end)
    if [ -e "$marker" ]; then
      rm -f "$marker"
      systemctl --user start --no-block gsr-replay.service
    fi
    ;;
  *)
    echo "usage: gsr-gamemode-hook start|end" >&2
    exit 2
    ;;
esac
