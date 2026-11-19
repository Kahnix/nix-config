mode="$1"
output="HDMI-A-2"

# Lua-configured Hyprland uses eval for runtime monitor changes.
hyprctl eval "hl.monitor({ output = '$output', mode = '$mode' })"
