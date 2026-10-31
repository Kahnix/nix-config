{
  # Zed beside Helix (hx stays EDITOR). Skipped on WSL, which has no desktop.
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      programs.zed-editor = lib.mkIf (!(osConfig.wsl.enable or false)) {
        enable = true;

        # Same language servers as hx, pinned by flake.lock, instead of the
        # binaries Zed would otherwise download into ~/.local/share/zed.
        extraPackages = config.programs.helix.extraPackages;

        # Merged into ~/.config/zed/settings.json; changes made in Zed's UI stay
        # (mutableUserSettings). Stylix supplies the theme and fonts.
        userSettings = {
          disable_ai = true;
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };
      };
    };
}
