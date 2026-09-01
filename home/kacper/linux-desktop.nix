{
  inputs,
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

let
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
      # Frozen snapshot of the live settings menu state; refresh with
      # scripts/snapshot-noctalia-settings.sh after tuning things in-app.
      settings = ./noctalia-settings.toml;
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
