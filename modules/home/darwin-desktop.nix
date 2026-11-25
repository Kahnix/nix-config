{
  # macOS desktop app integration. Tiling is handled by Spaceman (Homebrew cask
  # in the host config).
  flake.modules.homeManager.darwin-desktop = {
    # Copy GUI apps out of the Nix store so Spotlight and macOS permissions work
    # reliably while keeping their package definitions in Home Manager.
    targets.darwin.copyApps.enable = true;
    targets.darwin.linkApps.enable = false;

    # Home Manager uses macOS's native man implementation, so there is no
    # Home Manager man package from which to generate caches.
    programs.man.generateCaches = false;
  };
}
