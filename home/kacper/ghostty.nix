{
  lib,
  pkgs,
  isNixOS ? false,
  ...
}:

# Single Ghostty config shared by the NixOS desktop and macOS.
# Kanagawa Dragon + Berkeley Mono on both; only the window chrome differs.
let
  isDarwin = pkgs.stdenv.isDarwin;
in
lib.mkIf (isNixOS || isDarwin) {
  programs.ghostty = {
    enable = true;
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    enableFishIntegration = true;

    settings = {
      theme = "Kanagawa Dragon";
      # Berkeley Mono is installed natively per machine, not by Nix.
      # JetBrainsMono NFM supplies the Nerd Font glyphs it lacks.
      "font-family" = [
        "Berkeley Mono"
        "JetBrainsMono NFM"
      ];
      "font-size" = 12;
      "background-opacity" = 0.92;
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
    # Niri draws no client-side decorations; on macOS this would break
    # native fullscreen, so it stays Linux-only.
    // lib.optionalAttrs (!isDarwin) {
      "window-decoration" = false;
    };
  };
}
