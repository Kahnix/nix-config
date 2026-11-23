{
  unfreePackages = [ "vscode" ];

  # Vanilla VS Code beside Helix (hx stays EDITOR). Skipped on WSL, which has no desktop.
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      flake = ''(builtins.getFlake "${config.home.homeDirectory}/nix-config")'';
      system =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${flake}.darwinConfigurations.macbook-pro-m4"
        else if osConfig.wsl.enable or false then
          "${flake}.nixosConfigurations.wsl"
        else
          "${flake}.nixosConfigurations.nixos";
    in
    {
      programs.vscode = lib.mkIf (!(osConfig.wsl.enable or false)) {
        enable = true;

        # Chromium/Electron only auto-detects gnome-keyring under GNOME/XFCE;
        # on Hyprland it falls back to "basic" unless told explicitly.
        package =
          if pkgs.stdenv.hostPlatform.isLinux then
            pkgs.vscode.override {
              commandLineArgs = "--password-store=gnome-libsecret";
            }
          else
            pkgs.vscode;

        # Extensions live in VS Code's marketplace / Settings Sync rather than
        # Nix (except Stylix's theme extension) to avoid duplicate versions and
        # let VS Code manage updates directly.
        mutableExtensionsDir = true;

        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = true;

          # Writable settings.json: Home Manager merges only the Nix-managed keys
          # below (plus Stylix theme & fonts) on rebuild, leaving icon themes and
          # every other UI preference free to change in VS Code.
          mutableUserSettings = true;

          # Stylix's vscode target is disabled above so workbench.colorTheme stays
          # user-managed; keep the system fonts pinned here.
          userSettings = {
            "editor.fontFamily" = "BerkeleyMono Nerd Font";
            "editor.fontSize" = 12;
            "terminal.integrated.fontFamily" = "BerkeleyMono Nerd Font";
            "terminal.integrated.fontSize" = 12;
            "chat.fontFamily" = "Inter";
            "markdown.preview.fontFamily" = "Inter";

            "eslint.workingDirectories" = [ { mode = "auto"; } ];
            # Only run oxlint in repos with an oxlint config so it stays quiet in
            # ESLint repos (e.g. LoungeMatch).
            "oxc.requireConfig" = true;

            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            # nix.formatterPath is ignored when nix.enableLanguageServer is true;
            # nixd owns both formatting and flake/HM option completion here.
            "nix.serverSettings".nixd = {
              formatting.command = [ "nixfmt" ];
              nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
              options = {
                ${if pkgs.stdenv.hostPlatform.isDarwin then "nix-darwin" else "nixos"}.expr = "${system}.options";
                home-manager.expr = "${system}.options.home-manager.users.type.getSubOptions [ ]";
              };
            };

            "telemetry.telemetryLevel" = "off";
          };
        };
      };
    };
}
