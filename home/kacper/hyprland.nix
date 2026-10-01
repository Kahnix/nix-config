{
  config,
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:
let
  colors = config.lib.stylix.colors;
  screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = [ pkgs.hyprshot ];
    text = ''
      directory="$HOME/Pictures/Screenshots"
      mkdir -p "$directory"
      exec hyprshot -m "$1" -o "$directory"
    '';
  };
in
lib.optionalAttrs isNixOS {
  home.packages = [ screenshot ];

  # Consume Stylix's palette below, without also emitting its solid-border rules.
  stylix.targets.hyprland.enable = false;
  wayland.windowManager.hyprland = {
    enable = true;
    # NixOS owns the compositor/portal packages; UWSM owns the session lifecycle.
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";

    settings = {
      monitor = [
        {
          output = "HDMI-A-2";
          mode = "3440x1440@99.982";
          position = "auto";
          scale = 1;
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        }
      ];
      config = {
        general = {
          layout = "dwindle";
          gaps_in = 6;
          gaps_out = 12;
          border_size = 2;
          resize_on_border = true;
          allow_tearing = false;
          col = {
            active_border = {
              colors = [
                "rgb(${colors.base0D})"
                "rgb(${colors.base0C})"
              ];
              angle = 45;
            };
            inactive_border = "rgb(${colors.base02})";
          };
        };
        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
          shadow = {
            enabled = true;
            range = 16;
            render_power = 3;
            color = "rgba(00000055)";
          };
        };
        input = {
          kb_layout = "us";
          numlock_by_default = true;
          accel_profile = "flat";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            tap_to_click = true;
            disable_while_typing = true;
          };
        };
        dwindle.preserve_split = true;
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };
        # Keep X11 games at native pixel dimensions; the ultrawide uses scale 1.
        xwayland.force_zero_scaling = true;
      };
      curve = {
        _args = [
          "kanagawa"
          {
            type = "bezier";
            points = [
              [
                0.2
                1.0
              ]
              [
                0.3
                1.0
              ]
            ];
          }
        ];
      };
      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 3;
          bezier = "kanagawa";
          style = "slide";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 2;
          bezier = "kanagawa";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 3;
          bezier = "kanagawa";
          style = "slide";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 2;
          bezier = "kanagawa";
          style = "fade";
        }
        {
          leaf = "border";
          enabled = false;
        }
      ];
      # Quickshell animates its own panels; avoid double compositor animations.
      layer_rule = [
        {
          name = "quickshell-panels";
          match.namespace = "^(dms:.*|quickshell)$";
          no_anim = true;
        }
      ];
      window_rule = [
        {
          name = "quickshell-windows";
          match.class = "^com.danklinux.dms$";
          float = true;
        }
        {
          name = "desktop-dialogs";
          match.class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|org.gnome.FileRoller|system-monitor)$";
          float = true;
        }
        {
          name = "picture-in-picture";
          match.title = "^Picture-in-Picture$";
          float = true;
          pin = true;
        }
        # Upstream's Xwayland drag fix, without forcing game sizes/fullscreen.
        {
          name = "xwayland-drag-windows";
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
      ];
    };

    extraConfig = ''
      -- Desktop application shortcuts and native Hyprland tiling controls.
      local function app(key, command)
        hl.bind(key, hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- " .. command))
      end
      local function shell(key, command)
        hl.bind(key, hl.dsp.exec_cmd("${pkgs.dms-shell}/bin/dms ipc call " .. command))
      end

      app("SUPER + Return", "ghostty")
      app("SUPER + B", "zen-twilight")
      app("SUPER + E", "ghostty -e yazi")
      app("SUPER + CTRL + E", "thunar")
      app("SUPER + SHIFT + G", "steam")
      app("SUPER + SHIFT + V", "virt-manager")
      app("SUPER + CTRL + T", "ghostty --class=system-monitor -e btop")

      shell("SUPER + Space", "spotlight toggle")
      shell("SUPER + CTRL + Space", "control-center toggle")
      shell("SUPER + CTRL + V", "clipboard toggle")
      shell("SUPER + CTRL + D", "settings toggle")
      shell("SUPER + CTRL + L", "lock lock")
      shell("SUPER + SHIFT + E", "powermenu toggle")
      shell("SUPER + O", "hypr toggleOverview")
      shell("SUPER + SHIFT + slash", "hypr toggleBinds")
      hl.bind("SUPER + CTRL + SHIFT + E", hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm stop"))

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
        hl.bind(key, hl.dsp.exec_cmd("${lib.getExe screenshot} " .. mode))
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
    '';
  };
}
