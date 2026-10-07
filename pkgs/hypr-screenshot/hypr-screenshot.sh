directory="$HOME/Pictures/Screenshots"
mkdir -p "$directory"
exec hyprshot -m "$1" -o "$directory"
