-- Desktop application shortcuts and native Hyprland tiling controls.
-- Loaded by the Home Manager-generated hyprland.lua (extraLuaFiles.binds).

-- Tern lives in ~/.local/bin, which is only on shell PATHs, not the compositor's.
local tern = os.getenv("HOME") .. "/.local/bin/tern"

local function app(key, command)
  hl.bind(key, hl.dsp.exec_cmd("uwsm app -- " .. command))
end
local function shell(key, command)
  hl.bind(key, hl.dsp.exec_cmd("dms ipc call " .. command))
end

app("SUPER + Return", tern)
app("SUPER + B", "firefox")
app("SUPER + E", "thunar")
app("SUPER + SHIFT + G", "steam")
app("SUPER + SHIFT + V", "virt-manager")
app("SUPER + CTRL + T", tern .. " -e btop")

shell("SUPER + Space", "spotlight toggle")
shell("SUPER + CTRL + Space", "control-center toggle")
shell("SUPER + CTRL + V", "clipboard toggle")
shell("SUPER + CTRL + D", "settings toggle")
shell("SUPER + CTRL + L", "lock lock")
shell("SUPER + SHIFT + E", "powermenu toggle")
shell("SUPER + O", "hypr toggleOverview")
shell("SUPER + SHIFT + slash", "hypr toggleBinds")
hl.bind("SUPER + CTRL + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + C", hl.dsp.window.center())
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + W", hl.dsp.group.toggle())
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
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("gsr-replay save 60"))
hl.bind("SUPER + ALT + SHIFT + R", hl.dsp.exec_cmd("gsr-replay toggle"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
for key, action in pairs({ XF86AudioPlay = "play-pause", XF86AudioPause = "play-pause",
                           XF86AudioNext = "next", XF86AudioPrev = "previous" }) do
  hl.bind(key, hl.dsp.exec_cmd("playerctl " .. action), { locked = true })
end
