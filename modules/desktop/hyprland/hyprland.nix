{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.hyprland =
    { pkgs, ... }:
    {
      # NixOS owns the compositor and portal packages; UWSM owns the session
      # lifecycle (graphical-session.target, which starts the shell and the
      # user services); Home Manager only writes the config.
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      programs.dconf.enable = true;
      security.polkit.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };

      environment.sessionVariables = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
        # AWT under Xwayland on a non-reparenting compositor: without this, Swing
        # frames (RuneLite) never pick up resizes and paint at their initial size.
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      home-manager.sharedModules = [ homeModules.hyprland ];
    };

  flake.modules.homeManager.hyprland =
    { config, pkgs, ... }:
    let
      colors = config.lib.stylix.colors;
    in
    {
      home.packages = [ pkgs.hypr-screenshot ];

      # Consume Stylix's palette below, without also emitting its solid-border rules.
      stylix.targets.hyprland.enable = false;

      wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        systemd.enable = false;
        configType = "lua";

        # Key bindings are plain Lua, edited as a real file.
        extraLuaFiles.binds.content = ./binds.lua;

        settings = {
          monitor = [
            {
              output = "HDMI-A-2";
              mode = "3440x1440@99.982";
              position = "0x0";
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
                size = 6;
                passes = 2;
                # Keeps blur cheap on the GTX 1070: only re-blur what changed.
                new_optimizations = true;
                popups = true;
              };
              shadow = {
                enabled = true;
                range = 24;
                render_power = 3;
                color = "rgba(00000070)";
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
            cursor.warp_on_change_workspace = 1;
            dwindle.preserve_split = true;
            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
              # Notification actions from the shell may raise their window.
              focus_on_activate = true;
              # Frame rate for hidden render_unfocused windows (CS 1.6 below).
              # GoldSrc mixes ~100 ms of audio ahead per frame (snd_mixahead
              # 0.1), so 30 fps leaves a wide margin; the default 15 is close.
              render_unfocused_fps = 30;
              # VRR only for fullscreen windows tagged content "game" (see the
              # steam-games rule). Pascal drives G-Sync Compatible over DisplayPort
              # only; on HDMI the monitor reports no VRR capability and this is inert.
              vrr = 3;
            };
            # 2 = scan out fullscreen windows with content-type "game" straight
            # to the display, skipping the compositor copy: one frame less of
            # input latency. Debug with `hyprctl rollinglog | grep -i scanout`.
            render.direct_scanout = 2;
            # Keep X11 games at native pixel dimensions; the ultrawide uses scale 1.
            xwayland.force_zero_scaling = true;
            # No donation dialog or "what's new" window after updates.
            ecosystem = {
              no_donation_nag = true;
              no_update_news = true;
            };
          };
          curve = {
            _args = [
              "smooth"
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
              bezier = "smooth";
              style = "slide";
            }
            {
              leaf = "fade";
              enabled = true;
              speed = 2;
              bezier = "smooth";
            }
            {
              leaf = "workspaces";
              enabled = true;
              speed = 3;
              bezier = "smooth";
              style = "slide";
            }
            {
              leaf = "layers";
              enabled = true;
              speed = 2;
              bezier = "smooth";
              style = "fade";
            }
            {
              leaf = "border";
              enabled = false;
            }
          ];
          layer_rule = [
            # Quickshell animates its own panels; blur what sits behind their
            # translucent surfaces, but not the fully transparent margins.
            {
              name = "shell-surfaces";
              match.namespace = "^qs-(bar|panel|calendar|launcher|toast|osd|session)$";
              no_anim = true;
              blur = true;
              ignore_alpha = 0.3;
            }
            {
              name = "shell-wallpaper";
              match.namespace = "^qs-wallpaper$";
              no_anim = true;
            }
          ];
          window_rule = [
            {
              name = "desktop-dialogs";
              match.class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|.blueman-manager-wrapped|org.gnome.FileRoller|nm-connection-editor|nwg-displays)$";
              float = true;
            }
            {
              name = "dzgui";
              match.class = "(?i)^.?dzgui";
              float = true;
            }
            # Steam draws its own toast windows (class steam, title
            # notificationtoasts_<n>_desktop). As unmanaged floats they open centred
            # and steal focus; park them bottom-right, away from the shell's toasts.
            {
              name = "steam-notification-toasts";
              match = {
                class = "^steam$";
                title = "^notificationtoasts_.*";
              };
              float = true;
              pin = true;
              no_focus = true;
              no_anim = true;
              move = [
                "monitor_w-window_w-20"
                "monitor_h-window_h-20"
              ];
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
            # RuneLite's Swing tooltips, dropdowns, and sidebar popovers spawn as
            # heavyweight Xwayland sub-windows titled `win0`, `win1`, ... (or
            # untitled). Focusing, sliding, or decorating/blurring them makes
            # Swing dismiss or misrender them.
            {
              name = "runelite-popups";
              match = {
                class = "^net-runelite-(launcher-Launcher|client-RuneLite)$";
                title = "^(win[0-9]+)?$";
              };
              float = true;
              no_initial_focus = true;
              no_anim = true;
              no_blur = true;
              no_shadow = true;
              border_size = 0;
              rounding = 0;
            }
            # Proton games run through Xwayland and never announce a content
            # type, so tag them: render.direct_scanout = 2 only scans out
            # fullscreen "game" windows. Verify with `hyprctl monitors`
            # (directScanoutTo / directScanoutBlockedBy).
            {
              name = "steam-games";
              match.class = "^steam_app_[0-9]+$";
              content = "game";
            }
            # Counter-Strike 1.6 (GoldSrc, native, class hl_linux). A hidden
            # window gets no frame callbacks, so the engine blocks on its next
            # buffer swap while SDL's audio thread keeps replaying the last mixed
            # buffer: tabbing away loops/buzzes, and the game hitches on return.
            # render_unfocused keeps it drawing off-screen at render_unfocused_fps.
            {
              name = "cs16-keep-running";
              match.class = "^hl_linux$";
              content = "game";
              render_unfocused = true;
            }
          ];
        };
      };
    };
}
