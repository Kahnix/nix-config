-- Kacper's Hyprland desktop. This uses Hyprland's native Lua configuration.

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 2,
    col = {
      active_border = "rgba(e46876ee)",
      inactive_border = "rgba(363646cc)",
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 4,
    active_opacity = 1.0,
    inactive_opacity = 0.96,
    shadow = {
      enabled = true,
      range = 14,
      render_power = 3,
      color = "rgba(11111699)",
      offset = { 0, 4 },
    },
    blur = {
      enabled = true,
      size = 5,
      passes = 2,
      xray = false,
    },
  },

  animations = { enabled = true },
  input = {
    kb_layout = "us",
    numlock_by_default = true,
    follow_mouse = 1,
    sensitivity = 0.0,
  },
  dwindle = {
    preserve_split = true,
    smart_split = true,
    smart_resizing = true,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
    font_family = "Departure Mono",
  },
  cursor = {
    hide_on_key_press = true,
    no_hardware_cursors = true,
    warp_on_change_workspace = 1,
  },
  xwayland = { force_zero_scaling = true },
  binds = { hide_special_on_workspace_change = true },
})

hl.curve("outQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 2.2, bezier = "outQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.4, bezier = "outQuint", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "quick", style = "popin 94%" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 2.2, bezier = "outQuint", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.8, bezier = "outQuint", style = "slide" })

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user restart quickshell.service")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("hyprpolkitagent")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("udiskie --automount --smart-tray")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

local function bind(keys, description, dispatcher, flags)
  local options = flags or {}
  options.description = description
  hl.bind(keys, dispatcher, options)
end

bind("SUPER + RETURN", "Terminal", hl.dsp.exec_cmd("ghostty"))
bind("SUPER + SPACE", "Application launcher", hl.dsp.exec_cmd("qs -c kacper ipc call desktop toggleLauncher"))
bind("SUPER + CTRL + SPACE", "Control center", hl.dsp.exec_cmd("qs -c kacper ipc call desktop toggleControlCenter"))
bind("SUPER + B", "Browser", hl.dsp.exec_cmd("zen-beta"))
bind("SUPER + E", "Files", hl.dsp.exec_cmd("nautilus --new-window"))
bind("SUPER + SHIFT + G", "Gaming", hl.dsp.exec_cmd("steam"))
bind("SUPER + SHIFT + V", "Windows virtual machines", hl.dsp.exec_cmd("virt-manager"))
bind("SUPER + CTRL + V", "Clipboard history", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))
bind("SUPER + CTRL + T", "System monitor", hl.dsp.exec_cmd("ghostty --class=system-monitor -e btop"))
bind("SUPER + K", "Lock", hl.dsp.exec_cmd("hyprlock"))

bind("SUPER + W", "Close window", hl.dsp.window.close())
bind("SUPER + Q", "Close window", hl.dsp.window.close())
bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + SLASH", "Toggle split", hl.dsp.layout("togglesplit"))
bind("SUPER + P", "Pseudo tile", hl.dsp.window.pseudo())

local directions = {
  LEFT = "l",
  RIGHT = "r",
  UP = "u",
  DOWN = "d",
  H = "l",
  L = "r",
  K = "u",
  J = "d",
}

for key, direction in pairs(directions) do
  bind("SUPER + " .. key, "Focus " .. direction, hl.dsp.focus({ direction = direction }))
  bind("SUPER + SHIFT + " .. key, "Swap " .. direction, hl.dsp.window.swap({ direction = direction }))
end

for workspace = 1, 9 do
  local key = "code:" .. tostring(workspace + 9)
  bind("SUPER + " .. key, "Workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  bind("SUPER + SHIFT + " .. key, "Move to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + grave", "Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
bind("SUPER + SHIFT + grave", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

bind("PRINT", "Screenshot region", hl.dsp.exec_cmd("screenshot region"))
bind("SHIFT + PRINT", "Screenshot window", hl.dsp.exec_cmd("screenshot window"))
bind("CTRL + PRINT", "Screenshot monitor", hl.dsp.exec_cmd("screenshot output"))
bind("SUPER + PRINT", "Color picker", hl.dsp.exec_cmd("hyprpicker -a"))

bind("XF86AudioRaiseVolume", "Volume up", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "Volume down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
bind("XF86AudioMute", "Mute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioMicMute", "Mute microphone", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
bind("XF86AudioPlay", "Play or pause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", "Next track", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev", "Previous track", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.window_rule({ match = { class = "pavucontrol" }, float = true, center = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true, center = true })
hl.window_rule({ match = { class = "org.gnome.FileRoller" }, float = true, center = true })
hl.window_rule({ match = { class = "system-monitor" }, float = true, center = true })
