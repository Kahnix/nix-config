{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  # DankMaterialShell: bar, launcher, control center, notifications, clipboard,
  # wallpaper, lock screen, and the DankGreeter login screen.
  flake.modules.nixos.dms =
    { config, pkgs, ... }:
    {
      # The nixpkgs module installs DMS with Quickshell, matugen and cava, and
      # runs the package's own dms.service (Type=dbus, so DMS is the session
      # notification daemon; do not run mako/dunst) for graphical-session.target.
      programs.dms-shell = {
        enable = true;
        # Installed under /etc/xdg/quickshell/dms-plugins, DMS's system plugin dir.
        plugins = {
          screenRecorder.src = pkgs.dms-plugin-screen-recorder;
          dockerManager.src = pkgs.dms-plugin-docker-manager;
        };
      };
      # Stylix owns GTK/Qt/terminal colours; never let DMS's matugen override them.
      systemd.user.services.dms.environment.DMS_DISABLE_MATUGEN = "1";

      # DMS lock authenticates against the "dankshell" PAM service. Providing it
      # here lets the shell use system auth instead of its bundled fallback.
      security.pam.services.dankshell = { };

      services.displayManager = {
        defaultSession = "hyprland-uwsm";
        dms-greeter = {
          enable = true;
          compositor = {
            name = "hyprland";
            # Separate login compositor: no desktop services or application bindings.
            customConfig = ''
              hl.env("XCURSOR_THEME", "${config.stylix.cursor.name}")
              hl.env("XCURSOR_SIZE", "${toString config.stylix.cursor.size}")
              hl.config({
                misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
                input = { kb_layout = "us", numlock_by_default = true },
              })
            '';
          };
          # The module copies settings, wallpaper and custom theme into the
          # greeter's own directory; login never depends on home-directory access.
          configHome = config.users.users.${config.my.user}.home;
        };
      };

      # Seed the first login selection only; subsequent choices remain writable.
      systemd.tmpfiles.settings."10-dms-greeter" = {
        "/var/lib/dms-greeter/.local/state".d = {
          user = "dms-greeter";
          group = "dms-greeter";
          mode = "0700";
        };
        "/var/lib/dms-greeter/.local/state/memory.json".C = {
          user = "dms-greeter";
          group = "dms-greeter";
          mode = "0600";
          argument = toString (
            pkgs.writeText "dms-greeter-memory.json" (
              builtins.toJSON {
                lastSessionDesktopId = "hyprland-uwsm.desktop";
                lastSuccessfulUser = config.my.user;
              }
            )
          );
        };
      };

      home-manager.sharedModules = [ homeModules.dms ];
    };

  # Theme, wallpaper and first-launch settings. Settings are seeded once;
  # subsequent UI changes survive rebuilds.
  flake.modules.homeManager.dms =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      jsonFormat = pkgs.formats.json { };

      # Stylix exposes the active Base16 palette both with and without leading '#'.
      c = config.lib.stylix.colors.withHashtag;

      dmsTheme = jsonFormat.generate "dms-kanagawa-dragon-theme.json" {
        name = "Kanagawa Dragon";
        primary = c.base0D;
        primaryText = c.base00;
        primaryContainer = c.base0C;
        secondary = c.base0E;
        surface = c.base00;
        surfaceText = c.base05;
        surfaceVariant = c.base01;
        surfaceVariantText = c.base05;
        surfaceTint = c.base0D;
        background = c.base00;
        backgroundText = c.base05;
        outline = c.base03;
        surfaceContainer = c.base01;
        surfaceContainerHigh = c.base02;
        surfaceContainerHighest = c.base03;
        error = c.base08;
        warning = c.base0A;
        info = c.base0D;
        matugen_type = "scheme-neutral";
      };

      # Deterministic fallback wallpaper matching the dark graphite/slate palette.
      # DMS has no SVG image support, so generate a PNG at build time.
      dmsWallpaper =
        pkgs.runCommand "dms-kanagawa-dragon-wallpaper.png"
          {
            nativeBuildInputs = [ pkgs.imagemagick ];
          }
          ''
            magick -size 3440x1440 radial-gradient:"${c.base00}-${c.base02}" \
              -define png:exclude-chunks=time,date \
              $out
          '';

      fallbackWallpaperPath = "${config.xdg.dataHome}/backgrounds/dms-kanagawa-dragon.png";
      userWallpaperPath = "${config.home.homeDirectory}/Documents/wallpapers/31299713726712.jpg";

      # Non-default DMS settings only.  Defaults are omitted so the file stays
      # intentional and DMS can mutate it without HM symlink conflicts.
      dmsSettings = {
        currentThemeName = "custom";
        # Keep the mutable settings valid across theme updates and store GC.
        customThemeFile = "${config.xdg.configHome}/DankMaterialShell/kanagawa-dragon.json";

        # Stop DMS from driving external app theming; Stylix owns GTK/Qt/terminal
        # colours.  DMS_DISABLE_MATUGEN=1 is also set in the service environment.
        runDmsMatugenTemplates = false;
        runUserMatugenTemplates = false;

        # Typography
        fontFamily = "Inter";
        monoFontFamily = "JetBrainsMono Nerd Font";
        fontScale = 0.95;

        # Restrained shape and transparency
        cornerRadius = 12;
        popupTransparency = 0.92;
        floatingWindowTransparency = 0.92;

        # Fallback colour when no wallpaper is available
        wallpaperBackgroundColorMode = "custom";
        wallpaperBackgroundCustomColor = c.base00;

        # Launcher: compact Spotlight-style
        launcherStyle = "spotlight";

        # Workspace pills
        maxWorkspaceIcons = 0;
        groupWorkspaceApps = false;
        workspaceFocusedCustomColor = c.base0D;

        # Clock
        clockFormat = "24h";
        clockDateFormat = "ddd d";

        # Audio
        audioVisualizerEnabled = false;

        # Icons
        iconThemeDark = "Papirus-Dark";
        iconThemeLight = "Papirus-Dark";

        # Desktop host: no battery indicator.
        controlCenterShowBatteryIcon = false;

        # Lock screen
        lockScreenShowMediaPlayer = false;
        lockScreenShowWeather = false;

        # Power menu
        powerMenuActions = [
          "lock"
          "logout"
          "suspend"
          "reboot"
          "poweroff"
        ];
        powerMenuDefaultAction = "lock";
        # UWSM manages the Hyprland lifecycle; force logout through it so the
        # systemd user session shuts down cleanly even if auto-detection misfires.
        customPowerActionLogout = "uwsm stop";

        # Quiet
        soundsEnabled = false;

        # Hide resource monitors from the bar
        showCpuUsage = false;
        showMemUsage = false;

        # Single compact floating top bar
        barConfigs = [
          {
            id = "main";
            name = "Main Bar";
            enabled = true;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            attachToScreenEdge = false;
            position = 0; # top
            leftWidgets = [
              "launcherButton"
              "workspaceSwitcher"
              "focusedWindow"
            ];
            centerWidgets = [ "clock" ];
            rightWidgets = [
              "systemTray"
              "clipboard"
              "dockerManager"
              "notificationButton"
              "controlCenterButton"
            ];
            transparency = 0.92;
            bottomGap = 8;
            barLengthPadding = 16;
            fontScale = 0.95;
          }
        ];
      };

      settingsJson = jsonFormat.generate "dms-settings.json" dmsSettings;
      sessionJson =
        wallpaperPath:
        jsonFormat.generate "dms-session.json" {
          inherit wallpaperPath;
          wallpaperFillMode = "Fill";
        };
    in
    {
      home.packages = with pkgs; [
        # Runtime dependencies surfaced by the upstream module and DMS source.
        dgop
        dsearch

        # Screen Recorder's portal preflight uses gdbus and grep.
        glib
        gnugrep

        # Icon theme used by DMS and clipboard/launcher integrations.
        papirus-icon-theme
        wl-clipboard
      ];

      # Hard-disable DMS matugen so it never overrides Stylix.
      home.sessionVariables.DMS_DISABLE_MATUGEN = "1";

      xdg.configFile."DankMaterialShell/kanagawa-dragon.json".source = dmsTheme;
      xdg.dataFile."backgrounds/dms-kanagawa-dragon.png".source = dmsWallpaper;

      # Seed DMS defaults once.  After first login the files are owned by DMS and
      # user changes (wallpaper, settings tweaks) survive rebuilds.
      home.activation.seedDmsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settingsFile="${config.xdg.configHome}/DankMaterialShell/settings.json"
        sessionFile="${config.xdg.stateHome}/DankMaterialShell/session.json"

        if [ ! -f "$settingsFile" ]; then
          run install -Dm600 ${settingsJson} "$settingsFile"
        fi

        if [ ! -f "$sessionFile" ]; then
          if [ -f "${userWallpaperPath}" ]; then
            run install -Dm600 ${sessionJson userWallpaperPath} "$sessionFile"
          else
            run install -Dm600 ${sessionJson fallbackWallpaperPath} "$sessionFile"
          fi
        fi
      '';
    };
}
