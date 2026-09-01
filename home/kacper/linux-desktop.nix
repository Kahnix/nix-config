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
in
lib.mkIf isNixOS {
  home.packages = with pkgs; [
    blueman
    file-roller
    google-chrome
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

  programs = {
    noctalia = {
      enable = true;
      systemd.enable = true;
      # Frozen snapshot of the live settings menu state; refresh with
      # scripts/snapshot-noctalia-settings.sh after tuning things in-app.
      settings = builtins.fromTOML (builtins.readFile ./noctalia-settings.toml);
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
