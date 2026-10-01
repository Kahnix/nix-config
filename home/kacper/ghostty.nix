{
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

# Single Ghostty config shared by the NixOS desktop and macOS.
# Stylix owns its palette, font, size, and opacity.
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
lib.mkIf (isNixOS || isDarwin) {
  programs.ghostty = {
    enable = true;
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    enableFishIntegration = true;

    settings = {
      "background-blur" = 16;
      "window-padding-x" = 14;
      "window-padding-y" = 12;
      "confirm-close-surface" = false;
      keybind = [ "shift+enter=text:\\x1b\\r" ];
    }
    # Hides the titlebar but keeps the frame and rounded corners.
    // lib.optionalAttrs isDarwin {
      "macos-titlebar-style" = "hidden";
    }
    # Let Hyprland draw the window frame; macOS needs native decorations
    # for fullscreen support.
    // lib.optionalAttrs (!isDarwin) {
      "window-decoration" = false;
    };
  };
}
