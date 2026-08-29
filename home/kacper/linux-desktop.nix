{
  inputs,
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

let
  wallpaper = ../../assets/wallpapers/blue-hour.png;
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight;
in
lib.mkIf isNixOS {
  home.packages = with pkgs; [
    bibata-cursors
    blueman
    file-roller
    google-chrome
    kanagawa-gtk-theme
    kanagawa-icon-theme
    nautilus
    obsidian
    pavucontrol
    playerctl
    proton-pass
    proton-vpn
    protonmail-desktop
    satty
    telegram-desktop
    wl-clipboard
    xwayland-satellite
    zenBrowser
  ];

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.kanagawa-gtk-theme;
      name = "Kanagawa-BL";
    };
    iconTheme = {
      package = pkgs.kanagawa-icon-theme;
      name = "Kanagawa";
    };
    font = {
      name = "Inter";
      size = 11;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style = {
      name = "gtk2";
      package = pkgs.libsForQt5.qtstyleplugins;
    };
  };

  programs = {
    noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        shell = {
          corner_radius_scale = 0.85;
          font_family = "Berkeley Mono";
          time_format = "{:%H:%M}";
          date_format = "%A, %d %B";
          telemetry_enabled = false;
          polkit_agent = true;
          settings_show_advanced = true;
          niri_overview_type_to_launch_enabled = true;
          clipboard_enabled = true;
          clipboard_history_max_entries = 250;
          clipboard_keep_from_closed_apps = false;
          clipboard_auto_paste = "auto";
          clipboard_image_action_command = "satty -f -";

          animation = {
            enabled = true;
            speed = 1.15;
          };

          shadow = {
            direction = "down";
            alpha = 0.48;
          };

          panel = {
            transparency_mode = "glass";
            borders = true;
            shadow = true;
            launcher_placement = "floating";
            launcher_position = "center";
            clipboard_placement = "floating";
            clipboard_position = "center";
            control_center_placement = "attached";
            wallpaper_placement = "attached";
            session_placement = "attached";
            open_near_click_control_center = true;
          };

          launcher = {
            categories = true;
            show_icons = true;
            show_app_origin_indicator = false;
            compact = true;
            app_grid = false;
            sort_by_usage = true;
            provider_prefix = "/";
          };
        };

        wallpaper = {
          enabled = true;
          fill_mode = "crop";
          transition = [
            "fade"
            "wipe"
            "disc"
          ];
          transition_duration = 900;
          edge_smoothness = 0.25;
          transition_on_startup = true;
          directory = "${../../assets/wallpapers}";
          default.path = "${wallpaper}";
          automation.enabled = false;
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Kanagawa";
          pure_black_dark = false;
          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
            builtin_ids = [ ];
            community_ids = [ ];
          };
        };

        notification = {
          enable_daemon = true;
          show_app_name = true;
          show_actions = true;
          layer = "top";
          background_opacity = 0.95;
          offset_x = 14;
          offset_y = 8;
        };

        osd = {
          position = "top_right";
          orientation = "horizontal";
          background_opacity = 0.95;
          offset_x = 14;
          offset_y = 8;
        };

        lockscreen = {
          enabled = true;
          blurred_desktop = true;
          blur_intensity = 0.55;
          tint_intensity = 0.32;
          wallpaper = "${wallpaper}";
        };

        idle.behavior = {
          lock = {
            timeout = 900;
            action = "lock";
            enabled = true;
          };
          "screen-off" = {
            timeout = 960;
            action = "screen_off";
            enabled = true;
          };
        };

        bar.main = {
          position = "top";
          thickness = 36;
          background_opacity = 0.88;
          radius = 12;
          margin_ends = 12;
          margin_edge = 8;
          padding = 10;
          widget_spacing = 8;
          font_scale = 0.95;
          shadow = true;
          reserve_space = true;
          capsule = true;
          capsule_fill = "surface_variant";
          capsule_radius = 8.0;
          capsule_opacity = 0.85;
          start = [
            "launcher"
            "workspaces"
          ];
          center = [ "clock" ];
          end = [
            "media"
            "tray"
            "notifications"
            "clipboard"
            "network"
            "bluetooth"
            "volume"
            "control-center"
            "lock_button"
          ];
        };

        widget = {
          clock.format = "{:%a  %d %b   %H:%M}";
          notifications.hide_when_no_unread = true;
          network = {
            vpn_status = "replace";
            show_label = false;
            show_vpn_label = false;
          };
          lock_button = {
            type = "custom_button";
            glyph = "lock";
            tooltip = "Lock screen";
            actions.left = "exec noctalia msg session lock";
          };
        };

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "notification"; }
          { type = "wallpaper"; }
          { type = "screen_recorder"; }
        ];

        audio = {
          enable_overdrive = false;
          enable_sounds = false;
        };

        dock.enabled = false;
      };
    };
  };

  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  xsession.preferStatusNotifierItems = true;

  xdg = {
    enable = true;
    configFile = {
      "niri/config.kdl".source = ./niri.kdl;
      "satty/config.toml".text = ''
        [general]
        fullscreen = "current-screen"
        floating-hack = true
        early-exit = true
        early-exit-save-as = true
        initial-tool = "pointer"
        primary-highlighter = "block"
        copy-command = "wl-copy"
        actions-on-enter = ["save-to-clipboard", "exit"]
        actions-on-escape = ["exit"]
        actions-on-right-click = ["save-to-clipboard", "exit"]
        corner-roundness = 8
        font-family = "Berkeley Mono"
      '';
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  home.sessionVariables = {
    BROWSER = "zen-twilight";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
  };
}
