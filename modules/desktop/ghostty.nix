{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.ghostty =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
    in
    {
      home.sessionVariables = lib.mkIf isLinux { TERMINAL = "ghostty"; };

      # Single Ghostty config shared by the NixOS desktop and macOS.
      # Stylix owns its palette, font, size, and opacity.
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
        // lib.optionalAttrs isDarwin {
          # Hides the titlebar but keeps the frame and rounded corners.
          "macos-titlebar-style" = "hidden";
        }
        // lib.optionalAttrs isLinux {
          # Niri draws no client-side decorations; on macOS this would break
          # native fullscreen, so it stays Linux-only.
          "window-decoration" = false;
        };
      };
    };

  flake.modules.darwin.ghostty = {
    home-manager.sharedModules = [ homeModules.ghostty ];
  };

  flake.modules.nixos.ghostty = {
    home-manager.sharedModules = [ homeModules.ghostty ];
  };
}
