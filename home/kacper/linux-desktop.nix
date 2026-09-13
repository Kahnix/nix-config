{
  config,
  inputs,
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

let
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight;

  # Desktop entries used as default MIME handlers in xdg.mimeApps below. Celluloid
  # is a GTK4/libmpv frontend, so video inherits mpv's Wayland and NVDEC paths.
  videoPlayer = "io.github.celluloid_player.Celluloid.desktop";
  imageViewer = "swayimg.desktop";
  documentViewer = "org.pwmt.zathura.desktop";
  ebookReader = "com.github.johnfactotum.Foliate.desktop";
  musicPlayer = "org.strawberrymusicplayer.strawberry.desktop";
  textEditor = "org.gnome.gedit.desktop";
  fileManager = "thunar.desktop";

  gpartedWithDisplay = pkgs.gparted.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace gparted.in \
        --replace-fail \
          "@gksuprog@ '@bindir@/gparted' \"\$@\"" \
          "@gksuprog@ env DISPLAY=\"\$DISPLAY\" '@bindir@/gparted' \"\$@\""
    '';
  });

  # Replay-buffer control for the gsr-replay service below: niri binds call this
  # instead of raw pkill, so save/toggle are idempotent and failures are reported.
  gsrReplay = pkgs.writeShellApplication {
    name = "gsr-replay";
    runtimeInputs = with pkgs; [
      gpu-screen-recorder
      libnotify
      systemd
    ];
    text = ''
      sock="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/gsr.sock"

      # A missing notification daemon must not swallow the result.
      note() { notify-send "$@" || true; }

      case "''${1:-save}" in
        save)
          seconds="''${2:-60}"
          if path=$(gsr-cli -ipc "$sock" save-replay "$seconds"); then
            note "Replay saved" "$(basename "$path")"
            printf '%s\n' "$path"
          else
            note --urgency=critical "Replay buffer is not running" \
              "The last ''${seconds}s were not saved."
            exit 1
          fi
          ;;
        toggle)
          if gsr-cli -ipc "$sock" status >/dev/null 2>&1; then
            systemctl --user stop gsr-replay.service
            note "Replay buffer stopped"
          else
            systemctl --user start gsr-replay.service
            note "Replay buffer started"
          fi
          ;;
        *)
          echo "usage: gsr-replay [save [seconds] | toggle]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
lib.mkIf isNixOS {
  home.packages = with pkgs; [
    blueman
    cava
    celluloid
    file-roller
    foliate
    gallery-dl
    gdu
    gedit
    google-chrome
    mission-center
    mpv
    nautilus
    obsidian
    ouch
    pavucontrol
    playerctl
    proton-pass
    proton-vpn
    protonmail-desktop
    qalculate-gtk
    qbittorrent
    satty
    strawberry
    swayimg
    telegram-desktop
    # GUI file manager fallback; yazi (programs.yazi below) is the primary one.
    # tumbler/volman/archive-plugin give Thunar thumbnails, mounts and archives.
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    tesseract
    wl-clipboard
    yt-dlp
    # Quick one-shot capture, no KMS privilege needed:
    #   wf-recorder -c h264_nvenc -f ~/Videos/clip.mp4   (pkill -INT wf-recorder)
    wf-recorder
    discord
    xwayland-satellite
    zenBrowser
    gpartedWithDisplay
  ] ++ [ gsrReplay ];

  # ShadowPlay-style replay buffer. Capture goes through KMS (gsr-kms-server),
  # so it never waits on a portal dialog; SIGINT is GSR's "exit cleanly" signal.
  systemd.user.services.gsr-replay = {
    Unit = {
      Description = "GPU Screen Recorder replay buffer";
      PartOf = [ "graphical-session.target" ];
      # niri owns the outputs; KMS capture needs the session up but not a dialog.
      After = [ "niri.service" ];
    };

    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Videos/Replays";
      # NVENC is unusable on this driver (it reports NVENC API 13.0, ffmpeg wants
      # 13.1), so encode with Vulkan Video instead; switch to h264_software if it
      # misbehaves. One output only: with a second monitor attached, use
      # "-w HDMI-A-2" or "-w focused" instead of "-w screen".
      # Single line on purpose: Home Manager renders a list as one ExecStart=
      # per element, which systemd rejects for non-oneshot services.
      ExecStart = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder -w screen -f 60 -k h264_vulkan -c mp4 -r 60 -a default_output -o %h/Videos/Replays -ipc %t/gsr.sock";
      Restart = "on-failure";
      RestartSec = 5;
      KillSignal = "SIGINT";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Stylix does not cover icon themes in this revision, so set it by hand: GTK3
  # and GTK4 (Nautilus, Loupe, GNOME apps) pick it up through dconf.
  gtk.iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };

  # Stylix sets the *light* adw-gtk3 theme and relies on its generated CSS for
  # colours, but GTK3 widgets that use the theme's own base colours (file views
  # in Thunar, gedit) end up light. Prefer-dark makes GTK3 load adw-gtk3's
  # gtk-dark.css, which matches the dark desktop.
  gtk.colorScheme = "dark";

  # Appended to both gtk-3.0/gtk.css and gtk-4.0/gtk.css. libadwaita's chrome is
  # sized for a GNOME session, which reads oversized next to niri's 8px window
  # radius; trim it here. Selectors a toolkit does not know are ignored, so the
  # same block is safe for GTK3 and GTK4 -- @shade_color is defined by Stylix.
  stylix.targets.gtk.extraCss = ''
    headerbar { min-height: 38px; }
    windowcontrols button { min-height: 24px; min-width: 24px; padding: 0; margin: 0 2px; }
    .navigation-sidebar { border-right: 1px solid @shade_color; }
  '';

  programs = {
    noctalia = {
      enable = true;
      systemd.enable = true;
      # Frozen snapshot of the live settings menu state; refresh with
      # scripts/snapshot-noctalia-settings.sh after tuning things in-app.
      settings = builtins.fromTOML (builtins.readFile ./noctalia-settings.toml);
    };

    # Keyboard-first file manager. Stylix writes the base16 theme into
    # theme.toml; the extra packages give yazi previews for video, PDF and
    # archives. Its default `open` opener is xdg-open, so the handlers below
    # decide what a file opens with.
    yazi = {
      enable = true;
      enableFishIntegration = true;
      # yazi's built-in previewers shell out to these: ffmpeg/ffprobe for video
      # thumbnails, pdftoppm for PDF, 7zz for archives, magick for exotic images
      # (avif/heif/jxl) and font files, file(1) for MIME spotting.
      extraPackages = with pkgs; [
        _7zz
        ffmpeg
        file
        imagemagick
        poppler-utils
      ];
      settings = {
        mgr = {
          show_hidden = true;
          sort_dir_first = true;
        };

        # Enter/o on text and code files runs this (yazi's `open` rules send
        # text/* and code types to the `edit` opener). Spelled out rather than
        # relying on $EDITOR: niri inherits its environment at login, so a
        # session started before EDITOR changed keeps the old value for every
        # spawn. `block = true` hands the terminal to nvim and returns to yazi
        # on quit.
        opener.edit = [
          {
            run = "nvim %s";
            block = true;
            desc = "Neovim";
          }
        ];
      };
    };

    # Stylix fills zathurarc with the palette; zathura carries the mupdf backend.
    zathura.enable = true;
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

    # Owns ~/.config/mimeapps.list, which used to be a hand-written file (the
    # browser/Telegram/chrome entries below are ported from it).
    #
    # glib (Nautilus, gio) does not expand "video/*" or "image/*" defaults, so
    # the common types are listed individually; xdg-utils does expand them, hence
    # the wildcards stay for xdg-open/xdg-mime. Video goes to Celluloid, media and
    # documents to the apps added alongside it.
    mimeApps = {
      enable = true;

      associations.added = {
        "x-scheme-handler/http" = [
          "zen-twilight.desktop"
          "google-chrome.desktop"
        ];
        "x-scheme-handler/https" = [
          "zen-twilight.desktop"
          "google-chrome.desktop"
        ];
        "x-scheme-handler/chrome" = "zen-twilight.desktop";
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "text/html" = [
          "google-chrome.desktop"
          "zen-twilight.desktop"
        ];
        "application/xhtml+xml" = "zen-twilight.desktop";
        "application/x-extension-htm" = "zen-twilight.desktop";
        "application/x-extension-html" = "zen-twilight.desktop";
        "application/x-extension-shtml" = "zen-twilight.desktop";
        "application/x-extension-xhtml" = "zen-twilight.desktop";
        "application/x-extension-xht" = "zen-twilight.desktop";
      };

      defaultApplications = {
        "video/*" = videoPlayer;
        "video/mp4" = videoPlayer;
        "video/x-matroska" = videoPlayer;
        "video/webm" = videoPlayer;
        "video/quicktime" = videoPlayer;
        "video/x-msvideo" = videoPlayer;
        "video/mpeg" = videoPlayer;
        "video/mp2t" = videoPlayer;
        "video/ogg" = videoPlayer;
        "video/x-flv" = videoPlayer;
        "video/3gpp" = videoPlayer;
        "video/x-ms-wmv" = videoPlayer;
        "video/x-ms-asf" = videoPlayer;
        "video/x-m4v" = videoPlayer;

        "image/*" = imageViewer;
        "image/png" = imageViewer;
        "image/jpeg" = imageViewer;
        "image/gif" = imageViewer;
        "image/webp" = imageViewer;
        "image/bmp" = imageViewer;
        "image/tiff" = imageViewer;
        "image/avif" = imageViewer;

        "application/pdf" = documentViewer;
        "application/epub+zip" = ebookReader;

        "audio/*" = musicPlayer;
        "audio/mpeg" = musicPlayer;
        "audio/flac" = musicPlayer;
        "audio/ogg" = musicPlayer;
        "audio/x-wav" = musicPlayer;
        "audio/mp4" = musicPlayer;
        "audio/aac" = musicPlayer;
        "audio/opus" = musicPlayer;

        "text/plain" = textEditor;
        "text/markdown" = textEditor;

        # GUI double-click stays in a GUI file manager; yazi is bound in niri.
        "inode/directory" = fileManager;

        "x-scheme-handler/http" = "zen-twilight.desktop";
        "x-scheme-handler/https" = "zen-twilight.desktop";
        "x-scheme-handler/chrome" = "zen-twilight.desktop";
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "x-scheme-handler/discord-409416265891971072" = "discord-409416265891971072.desktop";
        "text/html" = "zen-twilight.desktop";
        "application/xhtml+xml" = "zen-twilight.desktop";
        "application/x-extension-htm" = "zen-twilight.desktop";
        "application/x-extension-html" = "zen-twilight.desktop";
        "application/x-extension-shtml" = "zen-twilight.desktop";
        "application/x-extension-xhtml" = "zen-twilight.desktop";
        "application/x-extension-xht" = "zen-twilight.desktop";
      };
    };

    configFile = {
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
        font-family = "${config.stylix.fonts.monospace.name}"
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
