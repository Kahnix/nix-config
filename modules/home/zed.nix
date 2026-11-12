{
  # Zed beside Helix (hx stays EDITOR). Skipped on WSL, which has no desktop.
  flake.modules.homeManager.dev =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      programs.zed-editor = lib.mkIf (!(osConfig.wsl.enable or false)) {
        enable = true;

        # Extensions referenced by the settings below; Zed installs them on
        # first start. Add others here if you want them on every host.
        extensions = [
          "astro"
          "emmet"
          "git-firefly"
          "html"
          "material-icon-theme"
          "nix"
        ];

        # Merged into ~/.config/zed/settings.json by the Home Manager module.
        # These keys win over edits made in Zed's UI; unknown/newer keys Zed
        # writes itself are left alone (mutableUserSettings).
        userSettings = {
          disable_ai = false;
          helix_mode = true;
          vim_mode = false;

          project_panel.dock = "left";
          outline_panel.dock = "left";
          collaboration_panel = {
            button = false;
            dock = "left";
          };
          git_panel.dock = "left";

          ssh_connections = [
            {
              host = "192.168.1.13";
              username = "kacper";
              args = [ ];
              projects = [
                { paths = [ "/" ]; }
                { paths = [ "/home/kacper" ]; }
              ];
            }
          ];

          language_models.opencode.show_zen_models = false;

          agent_servers = {
            opencode-v2 = {
              type = "registry";
              default_config_options = {
                effort = "high";
                model = "opencode-go/deepseek-v4.1-flash";
              };
            };
            antigravity-acp = {
              type = "registry";
              # The bundled Python/OpenSSL does not consult NixOS's certificate
              # store, so the Cloud Code calls made after login fail with
              # CERTIFICATE_VERIFY_FAILED (surfaced as "Internal error").
              env = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
                SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
              };
              default_config_options = {
                mode = "yolo";
                thinking_level = "medium";
                model = "gemini-4-argon";
              };
            };
          };

          icon_theme = {
            mode = "dark";
            light = "Material Icon Theme";
            dark = "Material Icon Theme";
          };

          edit_predictions = {
            allow_data_collection = "no";
            provider = "zed";
            mode = "subtle";
          };

          agent = {
            dock = "right";
            sandbox_permissions.allow_unsandboxed = true;
            tool_permissions = {
              default = "allow";
              tools = { };
            };
            favorite_models = [
              {
                provider = "opencode";
                model = "go/deepseek-v4.1-flash";
                enable_thinking = true;
                effort = "high";
              }
              {
                provider = "opencode";
                model = "go/gemini-4-argon";
                enable_thinking = true;
                effort = "high";
              }
            ];
            default_model = {
              effort = "high";
              enable_thinking = true;
              provider = "opencode";
              model = "go/deepseek-v4.1-flash";
            };
            commit_message_model = {
              provider = "opencode";
              model = "";
            };
            model_parameters = [ ];
          };

          ui_font_size = 14.666666666666666;
          buffer_font_size = 12.0;
          ui_font_family = "Inter";
          buffer_font_family = "BerkeleyMono Nerd Font";
          buffer_line_height = "standard";
          buffer_font_features = { };

          prettier.allowed = false;
          languages = {
            TypeScript = {
              code_actions_on_format."source.fixAll.eslint" = true;
              formatter = [ ];
              format_on_save = "on";
            };
            TSX = {
              code_actions_on_format."source.fixAll.eslint" = true;
              formatter = [ ];
              format_on_save = "on";
            };
          };
          lsp.eslint.settings.workingDirectory.mode = "auto";

          # Stylix sets userSettings.theme ("Base16 Gruvbox Paper") and writes
          # themes/stylix.json at normal priority.
          terminal.shell = "system";
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };
      };
    };
}
