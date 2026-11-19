-- Key bindings. Loaded by the Home Manager-generated hyprland.lua (extraLuaFiles.binds).
-- Shell panels are toggled over Quickshell IPC: `qs ipc call shell <function>`
-- (see IpcHandler in modules/desktop/quickshell/shell/shell.qml).

local function app(key, command)
  hl.bind(key, hl.dsp.exec_cmd("uwsm app -- " .. command))
end
local function shell(key, fn)
  hl.bind(key, hl.dsp.exec_cmd("qs ipc call shell " .. fn))
end

app("SUPER + Return", "ghostty")
app("SUPER + B", "firefox")
app("SUPER + E", "thunar")
app("SUPER + SHIFT + G", "steam")
app("SUPER + SHIFT + V", "virt-manager")
app("SUPER + CTRL + T", "ghostty -e btop")

shell("SUPER + Space", "launcher")
shell("SUPER + CTRL + Space", "controlCenter")
shell("SUPER + CTRL + V", "clipboard")
shell("SUPER + SHIFT + E", "session")
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + CTRL + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + C", hl.dsp.window.center())
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + W", hl.dsp.group.toggle())
hl.bind("SUPER + BracketLeft", hl.dsp.group.prev())
hl.bind("SUPER + BracketRight", hl.dsp.group.next())
hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))

local directions = { H = "left", J = "down", K = "up", L = "right",
                     Left = "left", Down = "down", Up = "up", Right = "right" }
for key, direction in pairs(directions) do
  hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
  hl.bind("SUPER + CTRL + SHIFT + " .. key, hl.dsp.window.move({ monitor = direction }))
end
for workspace = 1, 10 do
  local key = workspace % 10
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 80, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 80, relative = true }), { repeating = true })

for key, mode in pairs({ Print = "region", ["SHIFT + Print"] = "window",
                         ["CTRL + Print"] = "output", ["SUPER + SHIFT + S"] = "region",
                         ["SUPER + ALT + S"] = "window", ["SUPER + CTRL + S"] = "output" }) do
  hl.bind(key, hl.dsp.exec_cmd("hypr-screenshot " .. mode))
end

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
for key, action in pairs({ XF86AudioPlay = "play-pause", XF86AudioPause = "play-pause",
                           XF86AudioNext = "next", XF86AudioPrev = "previous" }) do
  hl.bind(key, hl.dsp.exec_cmd("playerctl " .. action), { locked = true })
end

hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "off" }))
