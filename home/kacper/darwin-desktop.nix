{
  lib,
  pkgs,
  ...
}:

let
  workspaces = map toString (lib.range 1 9);

  workspaceBindings = lib.listToAttrs (
    map (workspace: lib.nameValuePair "alt-${workspace}" "workspace ${workspace}") workspaces
  );

  moveToWorkspaceBindings = lib.listToAttrs (
    map (
      workspace: lib.nameValuePair "alt-shift-${workspace}" "move-node-to-workspace ${workspace}"
    ) workspaces
  );
in
lib.mkIf pkgs.stdenv.isDarwin {
  # Copy GUI apps out of the Nix store so Spotlight and macOS permissions work
  # reliably while keeping their package definitions in Home Manager.
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = true;

    settings = {
      theme = "Kanagawa Dragon";
      "macos-titlebar-style" = "hidden";
      "window-padding-x" = 10;
      "window-padding-y" = 10;
      "window-padding-balance" = true;

      # Preserve the existing Shift+Enter escape-sequence binding.
      keybind = [ "shift+enter=text:\\x1b\\r" ];
    };
  };

  programs.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    # Home Manager owns startup and config reloads through launchd.
    launchd.enable = true;

    settings = {
      "config-version" = 2;
      "start-at-login" = true;
      "auto-reload-config" = true;

      "enable-normalization-flatten-containers" = true;
      "enable-normalization-opposite-orientation-for-nested-containers" = true;
      "default-root-container-layout" = "tiles";
      "default-root-container-orientation" = "auto";
      "accordion-padding" = 28;

      "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];
      "persistent-workspaces" = workspaces;
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 10;
        outer.bottom = 10;
        # macOS already reserves room for its native menu bar.
        outer.top = 10;
        outer.right = 10;
      };

      mode.main.binding =
        workspaceBindings
        // moveToWorkspaceBindings
        // {
          alt-enter = "exec-and-forget open -na Ghostty";

          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";

          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-shift-space = "layout floating tiling";
          alt-shift-f = "fullscreen";
          alt-shift-r = [
            "flatten-workspace-tree"
            "layout h_tiles"
            "balance-sizes"
          ];
          alt-minus = "resize smart -50";
          alt-equal = "resize smart +50";

          alt-tab = "workspace-back-and-forth";
          alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
          alt-shift-semicolon = "mode service";
        };

      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        r = [
          "flatten-workspace-tree"
          "layout h_tiles"
          "balance-sizes"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];
        alt-shift-h = [
          "join-with left"
          "mode main"
        ];
        alt-shift-j = [
          "join-with down"
          "mode main"
        ];
        alt-shift-k = [
          "join-with up"
          "mode main"
        ];
        alt-shift-l = [
          "join-with right"
          "mode main"
        ];
      };

      # Keep normal app windows in the tiling tree; float only small utilities.
      "on-window-detected" = [
        {
          # Terminals should always join the active tiling tree. In particular,
          # do not treat Ghostty's compact initial frame as a dialog.
          "if".app-id = "com.mitchellh.ghostty";
          run = "layout tiling";
        }
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.calculator";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.SecurityAgent";
          run = "layout floating";
        }
      ];
    };
  };
}
