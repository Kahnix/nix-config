mode="$1"
output="HDMI-A-2"

# Temporary change; config.kdl is not modified.
niri msg output "$output" mode "$mode"
