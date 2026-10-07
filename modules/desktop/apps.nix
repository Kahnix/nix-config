{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  unfreePackages = [
    "discord"
    "discord-unwrapped"
    "firefox-bin"
    "firefox-bin-unwrapped"
    "google-chrome"
    "obsidian"
  ];

  # Desktop applications, file handling and the session services they rely on.
  flake.modules.nixos.desktop-apps = {
    services = {
      udisks2.enable = true;
      upower.enable = true;
      gvfs.enable = true;
      gnome.gnome-keyring.enable = true;
      # AT-SPI bus. omp's computer use enumerates windows and reads accessibility
      # trees over it; without the bus those calls fail with the nixpkgs-documented
      # "org.a11y.Bus was not provided by any .service files".
      gnome.at-spi2-core.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # nixpkgs defaults EDITOR to `nano` with lib.mkDefault; a plain assignment
    # wins. This is what yazi's built-in `edit` opener runs ("${EDITOR:-vi} %s",
    # blocking), and what git, ssh and everything else picks up.
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    home-manager.sharedModules = [ homeModules.desktop-apps ];
  };

  flake.modules.homeManager.desktop-apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Desktop entries used as default MIME handlers below. Celluloid is a
      # GTK4/libmpv frontend, so video inherits mpv's Wayland and NVDEC paths.
      videoPlayer = "io.github.celluloid_player.Celluloid.desktop";
      imageViewer = "swayimg.desktop";
      documentViewer = "org.pwmt.zathura.desktop";
      ebookReader = "com.github.johnfactotum.Foliate.desktop";
      musicPlayer = "org.strawberrymusicplayer.strawberry.desktop";
      textEditor = "org.gnome.gedit.desktop";
      fileManager = "thunar.desktop";
      browser = "firefox.desktop";

      handledBy = app: types: lib.genAttrs types (_: app);

      # glib (Nautilus, gio) does not expand "video/*" or "image/*" defaults, so
      # the common types are listed individually; xdg-utils does expand them,
      # hence the wildcards stay for xdg-open/xdg-mime.
      videoTypes = [
        "video/*"
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/quicktime"
        "video/x-msvideo"
        "video/mpeg"
        "video/mp2t"
        "video/ogg"
        "video/x-flv"
        "video/3gpp"
        "video/x-ms-wmv"
        "video/x-ms-asf"
        "video/x-m4v"
      ];
      imageTypes = [
        "image/*"
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/tiff"
        "image/avif"
      ];
      audioTypes = [
        "audio/*"
        "audio/mpeg"
        "audio/flac"
        "audio/ogg"
        "audio/x-wav"
        "audio/mp4"
        "audio/aac"
        "audio/opus"
      ];
      webTypes = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chrome"
        "text/html"
        "application/xhtml+xml"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-xht"
      ];
    in
    {
      # Only the Linux desktop needs omp's PipeWire-backed Wayland capture addon.
      my.omp.waylandScreencast = true;

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
        zed-editor
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
        # GUI file manager (Super + E). Yazi stays installed for use from a shell.
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
        firefox-bin
        gparted-with-display
      ];

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

      # Trim oversized GTK headerbars to match the compact Hyprland desktop.
      # Unknown selectors are ignored by GTK3/GTK4; Stylix defines @shade_color.
      stylix.targets.gtk.extraCss = ''
        headerbar { min-height: 38px; }
        windowcontrols button { min-height: 24px; min-width: 24px; padding: 0; margin: 0 2px; }
        .navigation-sidebar { border-right: 1px solid @shade_color; }
      '';

      programs = {
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
            exiftool
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
            # relying on $EDITOR: the compositor inherits its environment at login, so a
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

        # Owns ~/.config/mimeapps.list.
        mimeApps = {
          enable = true;

          associations.added = handledBy browser webTypes // {
            "x-scheme-handler/http" = [
              "firefox.desktop"
              "google-chrome.desktop"
            ];
            "x-scheme-handler/https" = [
              "firefox.desktop"
              "google-chrome.desktop"
            ];
            "text/html" = [
              "google-chrome.desktop"
              "firefox.desktop"
            ];
            "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
            "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
          };

          defaultApplications =
            handledBy videoPlayer videoTypes
            // handledBy imageViewer imageTypes
            // handledBy musicPlayer audioTypes
            // handledBy browser webTypes
            // {
              "application/pdf" = documentViewer;
              "application/epub+zip" = ebookReader;

              "text/plain" = textEditor;
              "text/markdown" = textEditor;

              # GUI double-click and Super + E both open the GUI file manager.
              "inode/directory" = fileManager;

              "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
              "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
              "x-scheme-handler/discord-409416265891971072" = "discord-409416265891971072.desktop";
            };
        };

        configFile."satty/config.toml".text = ''
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

        userDirs = {
          enable = true;
          createDirectories = true;
        };
      };

      home.sessionVariables = {
        BROWSER = "firefox";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
      };
    };
}
