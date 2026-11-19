{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;

  # Vector logo rendered at the monitor's native 3440x1440, tinted from the
  # Stylix scheme, so it follows the theme and never gets upscaled. Shared by
  # the shell's wallpaper, hyprlock and the greeter.
  wallpaperFor =
    pkgs: colors:
    pkgs.runCommand "nixos-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 3440x1440 xc:'#${colors.base00}' \
        \( -background none -density 1200 \
           ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg \
           -resize x700 -fill '#${colors.base02}' -colorize 100 \) \
        -gravity center -composite -depth 8 $out
    '';
in
{
  # Quickshell desktop shell (./shell): bar, launcher, clipboard picker,
  # control center, notifications, OSD, session menu and wallpaper. Around it:
  # hyprlock + hypridle for locking, hyprpolkitagent, cliphist, and ReGreet.
  flake.modules.nixos.quickshell =
    { config, pkgs, ... }:
    {
      # The control center's record toggle drives gpu-screen-recorder; the module
      # adds the setcap'd gsr-kms-server wrapper that direct monitor (KMS) capture needs.
      programs.gpu-screen-recorder = {
        enable = true;
        # gsr hard-codes "libavcodec 63 needs NVENC API 13.1" and hides every
        # NVENC codec on the legacy_580 driver (13.0), yet FFmpeg 9 encodes
        # h264/hevc_nvenc on it fine. Lowering the gate keeps the cached FFmpeg 9;
        # overriding to FFmpeg 8 instead compiles FFmpeg on every nixpkgs bump.
        package = pkgs.gpu-screen-recorder.overrideAttrs (prev: {
          postPatch = (prev.postPatch or "") + ''
            substituteInPlace src/codec_query/nvenc.c \
              --replace-fail "NVENCAPI_PACKED_VERSION(13, 1)" "NVENCAPI_PACKED_VERSION(13, 0)"
          '';
        });
      };

      # PAM service for hyprlock.
      programs.hyprlock.enable = true;

      # greetd + ReGreet in cage; Stylix themes it. It remembers the last
      # session and user, so the first login picks "Hyprland (UWSM)" once.
      services.displayManager.regreet = {
        enable = true;
        settings = {
          background = {
            path = wallpaperFor pkgs config.lib.stylix.colors;
            fit = "Cover";
          };
          GTK.application_prefer_dark_theme = true;
        };
      };
      # Unlocks the login keyring with the greetd password.
      security.pam.services.greetd.enableGnomeKeyring = true;

      home-manager.sharedModules = [ homeModules.quickshell ];
    };

  flake.modules.homeManager.quickshell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      colors = config.lib.stylix.colors;
      c = colors.withHashtag;
      fonts = config.stylix.fonts;
      wallpaper = wallpaperFor pkgs colors;
      nixIcon =
        pkgs.runCommand "nix-accent.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick -background none -density 400 \
            ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg \
            -trim +repage -resize 54x54 -gravity center -extent 64x64 \
            -fill '#${colors.base0D}' -colorize 100 $out
        '';

      # Raw bar heights for the media visualizer: 10 bars, 0..100, one frame
      # per line. Only runs while something is playing.
      cavaConfig = pkgs.writeText "cava.conf" ''
        [general]
        bars = 10
        framerate = 30
        [input]
        method = pipewire
        [output]
        method = raw
        raw_target = /dev/stdout
        data_format = ascii
        ascii_max_range = 100
        bar_delimiter = 59
        frame_delimiter = 10
      '';

      # Stylix values (and a few store paths) the QML reads as the `Stylix` singleton.
      palette = pkgs.writeText "Stylix.qml" ''
        pragma Singleton
        import QtQuick
        import Quickshell

        Singleton {
        ${lib.concatMapStrings (n: "  readonly property color ${n}: \"${c.${n}}\"\n") (
          map (i: "base0${i}") [
            "0"
            "1"
            "2"
            "3"
            "4"
            "5"
            "6"
            "7"
            "8"
            "9"
            "A"
            "B"
            "C"
            "D"
            "E"
            "F"
          ]
        )}
          readonly property string sans: "${fonts.sansSerif.name}"
          readonly property string mono: "${fonts.monospace.name}"
          readonly property real opacity: ${toString config.stylix.opacity.desktop}
          readonly property string wallpaper: "${wallpaper}"
          readonly property string nixIcon: "${nixIcon}"
          readonly property var cava: ["${lib.getExe pkgs.cava}", "-p", "${cavaConfig}"]
        }
      '';

      # Stylix's Noto 3D emoji font reports a ~200px line height to Qt, so one
      # emoji in a track title or notification blows up the layout around it.
      # The shell alone falls back to the flat Noto Color Emoji instead.
      fontconfig = pkgs.writeText "quickshell-fonts.conf" ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
          <dir>${pkgs.noto-fonts-color-emoji}/share/fonts</dir>
          <selectfont><rejectfont><glob>*Noto-3D-*.ttf</glob></rejectfont></selectfont>
        </fontconfig>
      '';

      shell = pkgs.runCommandLocal "quickshell-config" { } ''
        cp -r ${./shell} $out
        chmod u+w $out
        cp ${palette} $out/Stylix.qml
      '';
    in
    {
      home.packages = with pkgs; [
        cliphist
        libnotify
        wl-clipboard
      ];

      # The shell lives at ~/.config/quickshell itself (not a named config), so
      # plain `qs ipc call shell <fn>` reaches it. Started by the HM unit for
      # graphical-session.target, which UWSM brings up.
      xdg.configFile."quickshell".source = shell;
      programs.quickshell = {
        enable = true;
        systemd.enable = true;
      };
      systemd.user.services.quickshell = {
        # Reload on rebuilds: the store path behind ~/.config/quickshell changes.
        Unit.X-Restart-Triggers = [ "${shell}" ];
        Service.Environment = [ "FONTCONFIG_FILE=${fontconfig}" ];
      };

      services.cliphist = {
        enable = true;
        allowImages = true;
        extraOptions = [
          "-max-items"
          "250"
        ];
      };

      services.hyprpolkitagent.enable = true;

      # Lock after 15 min, screen off a minute later; lock before suspend.
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
          };
          listener = [
            {
              timeout = 900;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 960;
              on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
              on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
            }
          ];
        };
      };

      # Styled here to match the shell; Stylix's target would add its own
      # background and input colours on top.
      stylix.targets.hyprlock.enable = false;
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            hide_cursor = true;
            ignore_empty_input = true;
          };
          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
              brightness = 0.55;
              color = "rgb(${colors.base00})";
            }
          ];
          label = [
            {
              text = "$TIME";
              font_family = fonts.monospace.name;
              font_size = 112;
              color = "rgb(${colors.base05})";
              position = "0, 140";
              halign = "center";
              valign = "center";
            }
            {
              text = ''cmd[update:60000] date +"%A, %d %B"'';
              font_family = fonts.sansSerif.name;
              font_size = 18;
              color = "rgb(${colors.base04})";
              position = "0, 50";
              halign = "center";
              valign = "center";
            }
          ];
          input-field = [
            {
              size = "320, 52";
              outline_thickness = 2;
              rounding = 12;
              dots_size = 0.22;
              dots_spacing = 0.35;
              outer_color = "rgb(${colors.base02})";
              inner_color = "rgba(${colors.base01}e6)";
              font_color = "rgb(${colors.base05})";
              check_color = "rgb(${colors.base0D})";
              fail_color = "rgb(${colors.base08})";
              capslock_color = "rgb(${colors.base0A})";
              font_family = fonts.monospace.name;
              placeholder_text = "password";
              fail_text = "$FAIL";
              fade_on_empty = false;
              position = "0, -60";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
