app_id="$1"
shift

id=$(niri msg --json windows | jq -r --arg app_id "$app_id" \
  'first(.[] | select(.app_id == $app_id) | .id) // empty')

if [ -n "$id" ]; then
  exec niri msg action focus-window --id "$id"
fi
exec "$@"
