{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.hyprland = { pkgs, ... }: {
    # NixOS owns the compositor and portal packages; UWSM owns the session
    # lifecycle; Home Manager only writes the config.
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    # Launch via Hyprland's own session entry (the upstream-documented
    # `uwsm start hyprland.desktop`): uwsm runs its Exec, start-hyprland (the
    # watchdog launcher), and takes DesktopNames=Hyprland from it, so
    # XDG_CURRENT_DESKTOP is plain "Hyprland". Pointing binPath at the
    # start-hyprland binary instead makes it "start-hyprland:Hyprland".
    programs.uwsm.waylandCompositors.hyprland = {
      # NixOS appends " (UWSM)" to prettyName, so the greeter label becomes
      # "Hyprland + Quickshell (UWSM)".
      prettyName = "Hyprland + Quickshell";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/share/wayland-sessions/hyprland.desktop";
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
            # 2 = scan out fullscreen windows with content-type "game" straight
            # to the display, skipping the compositor copy: one frame less of
            # input latency. Debug with `hyprctl rollinglog | grep -i scanout`.
            render.direct_scanout = 2;
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
              match.class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|org.gnome.FileRoller)$";
              float = true;
            }
            # Steam draws its own toast windows (class steam, title
            # notificationtoasts_<n>_desktop). As unmanaged floats they open centred
            # and steal focus; park them bottom-right, out of DMS's popup corner.
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
            # Proton games run through Xwayland and never announce a content
            # type, so tag them: render.direct_scanout = 2 only scans out
            # fullscreen "game" windows. Verify with `hyprctl monitors`
            # (directScanoutTo / directScanoutBlockedBy).
            {
              name = "steam-games";
              match.class = "^steam_app_[0-9]+$";
              content = "game";
            }
          ];
        };
      };
    };
}
