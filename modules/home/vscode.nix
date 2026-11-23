{
  unfreePackages = [ "vscode" ];

  # Vanilla VS Code beside Helix (hx stays EDITOR). Skipped on WSL, which has no desktop.
  flake.modules.homeManager.dev =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      programs.vscode = lib.mkIf (!(osConfig.wsl.enable or false)) {
        enable = true;

        # Keep extensions mutable so marketplace extensions (e.g. Antigravity,
        # browser/agent tools) can be installed and updated from VS Code's UI.
        mutableExtensionsDir = true;

        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = true;

          extensions = with pkgs.vscode-extensions; [
            astro-build.astro-vscode
            bradlc.vscode-tailwindcss
            dbaeumer.vscode-eslint
            jnoortheen.nix-ide
            oxc.oxc-vscode
            pkief.material-icon-theme
          ];

          # Stylix supplies workbench.colorTheme ("Stylix"), editor/chat/markdown
          # fontFamily and fontSize, and terminal.integrated.fontSize.
          userSettings = {
            "workbench.iconTheme" = "material-icon-theme";
            "window.titleBarStyle" = "custom";
            "terminal.integrated.fontFamily" = "BerkeleyMono Nerd Font";

            "editor.formatOnSave" = true;
            "eslint.workingDirectories" = [ { mode = "auto"; } ];

            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            "nix.formatterPath" = "nixfmt";

            "telemetry.telemetryLevel" = "off";
          };
        };
      };
    };
}
