{
  config,
  inputs,
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

let
  wallpaper = ../../assets/wallpapers/blue-hour.png;
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      coreutils
      hyprshot
      satty
    ];
    text = ''
      mode="''${1:-region}"
      case "$mode" in
        region|window|output) ;;
        *)
          echo "usage: screenshot [region|window|output]" >&2
          exit 2
          ;;
      esac

      screenshot_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$screenshot_dir"
      filename="$screenshot_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

      hyprshot -m "$mode" -r |
        satty --filename - --output-filename "$filename"
    '';
  };

  phoneMicrophone = pkgs.writeShellApplication {
    name = "phone-mic";
    runtimeInputs = with pkgs; [
      pulseaudio
      scrcpy
    ];
    text = ''
      sink_module=""
      source_module=""

      cleanup() {
        if [[ -n "$source_module" ]]; then
          pactl unload-module "$source_module" || true
        fi
        if [[ -n "$sink_module" ]]; then
          pactl unload-module "$sink_module" || true
        fi
      }
      trap cleanup EXIT

      sink_module="$(pactl load-module module-null-sink \
        sink_name=phone_mic \
        rate=48000 \
        channels=1 \
        sink_properties=device.description=Phone_Microphone)"
      source_module="$(pactl load-module module-remap-source \
        master=phone_mic.monitor \
        source_name=phone_mic \
        channels=1 \
        source_properties=device.description=Phone_Microphone)"

      export PULSE_SINK=phone_mic
      echo "Phone Microphone is live. Select it in Discord or another app."
      scrcpy --no-window --audio-source=mic --audio-buffer=50 "$@"
    '';
  };
in
lib.mkIf isNixOS {
  home.packages = with pkgs; [
    adw-gtk3
    bibata-cursors
    blueman
    cliphist
    file-roller
    fuzzel
    google-chrome
    grim
    hyprlock
    hyprpaper
    hyprpicker
    hyprpolkitagent
    hyprshot
    nautilus
    networkmanagerapplet
    nwg-look
    obsidian
    papirus-icon-theme
    pavucontrol
    playerctl
    proton-pass
    proton-vpn
    protonmail-desktop
    quickshell
    satty
    scrcpy
    slurp
    telegram-desktop
    udiskie
    vesktop
    wl-clipboard
    zenBrowser
    phoneMicrophone
    screenshot
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
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    font = {
      name = "Departure Mono";
      size = 11;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      theme = "Kanagawa Wave";
      "font-family" = "Departure Mono";
      "font-size" = 12;
      "background-opacity" = 0.94;
      "background-blur-radius" = 10;
      "window-decoration" = false;
      "window-padding-x" = 12;
      "window-padding-y" = 10;
      "confirm-close-surface" = false;
      keybind = [ "shift+enter=text:\\x1b\\r" ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 1;
      };

      background = {
        path = "${wallpaper}";
        blur_passes = 2;
        blur_size = 5;
        color = "rgb(111116)";
      };

      label = [
        {
          text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';
          color = "rgb(dcd7ba)";
          font_family = "Departure Mono";
          font_size = 72;
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          text = ''cmd[update:60000] echo "$(date +"%A, %d %B")"'';
          color = "rgb(727169)";
          font_family = "Departure Mono";
          font_size = 16;
          position = "0, 20";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = {
        size = "280, 42";
        position = "0, -80";
        halign = "center";
        valign = "center";
        outline_thickness = 1;
        rounding = 4;
        outer_color = "rgb(363646)";
        inner_color = "rgba(111116ee)";
        font_color = "rgb(dcd7ba)";
        check_color = "rgb(7e9cd8)";
        fail_color = "rgb(e46876)";
        placeholder_text = "Password";
        fail_text = "Authentication failed";
        dots_center = true;
        fade_on_empty = false;
      };
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "hypr/hyprland.lua".source = ./hyprland.lua;
      "quickshell/kacper" = {
        source = ./quickshell;
        recursive = true;
      };
      "hypr/hyprpaper.conf".text = ''
        preload = ${wallpaper}
        wallpaper = ,${wallpaper}
        splash = false
        ipc = false
      '';
      "satty/config.toml".text = ''
        [general]
        fullscreen = "current-screen"
        floating-hack = true
        early-exit = true
        early-exit-save-as = true
        initial-tool = "pointer"
        primary-highlighter = "block"
        copy-command = "wl-copy"
        actions-on-enter = ["save-to-clipboard", "save-to-file", "exit"]
        actions-on-escape = ["exit"]
        actions-on-right-click = ["save-to-clipboard", "save-to-file", "exit"]
        corner-roundness = 4
        font-family = "Departure Mono"
      '';
    };

    desktopEntries.phone-microphone = {
      name = "Phone Microphone";
      genericName = "Android microphone bridge";
      comment = "Expose an Android phone microphone through PipeWire";
      exec = "ghostty --class=phone-mic -e phone-mic";
      icon = "audio-input-microphone";
      terminal = false;
      categories = [ "AudioVideo" ];
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  home.sessionVariables = {
    BROWSER = "zen-beta";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "ghostty";
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Kacper's Quickshell desktop";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c kacper";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
