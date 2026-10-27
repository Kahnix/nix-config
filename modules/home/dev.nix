{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      omp =
        (inputs.oh-my-pi.packages.${system}.omp.override {
          withWaylandScreencast = config.my.omp.waylandScreencast;
        }).overrideAttrs
          (old: {
            CARGO_PROFILE_RELEASE_LTO = "off";
            CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
            env = old.env // {
              RUSTFLAGS = "${old.env.RUSTFLAGS or ""} -Zthreads=8";
            };
          });
    in
    {
      options.my.omp.waylandScreencast = lib.mkEnableOption "omp's PipeWire-backed Wayland capture addon";

      config.home.packages =
        (with pkgs; [
          tree-sitter
          git-lfs
          btop
          ripgrep
          fd
          jq
          bat
          eza
          unzip
          tree
          nodejs
          nil
          pnpm
          inputs.bunnix.packages.${system}.v1_3_14
          deno
          go
          rustup
          python3
          nixd
          lua-language-server
          redis
          sqlite
          tailwindcss-language-server
          typescript
          typescript-language-server
          vscode-langservers-extracted
          yaml-language-server
          just
          httpie
          xh
          yq
          delta
          devenv
          nixfmt
          hydra-check
          nix-index
          nix-init
          nix-inspect
          nix-melt
          nix-output-monitor
          nix-search-tv
          nix-tree
          nvd
          opencode
          omp
          herdr
        ])
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            gcc
            # Linux FHS wrapper; macOS installs the burp-suite Homebrew cask.
            burpsuite
          ]
        );

      # Helix config is generated: ~/.config/helix/{config,languages}.toml are
      # read-only store symlinks, so editor settings live here. Stylix's helix
      # target writes themes/stylix.toml and defines `settings.theme` itself;
      # setting theme here would be a second, conflicting definition.
      config.programs.helix = {
        enable = true;

        # Shells get EDITOR/VISUAL from here on every host; NixOS also keeps
        # `hx` in environment.variables because GUI apps inherit their
        # environment from the compositor, not from a shell.
        defaultEditor = true;

        # hx only finds language servers on PATH. The Mason installs Neovim used
        # lived under ~/.local/share/nvim and were never on PATH.
        extraPackages = with pkgs; [
          clang-tools # clangd
          gopls
          golangci-lint
          golangci-lint-langserver
          oxlint
          oxfmt
          # Not wired to any language: a repo that wants it sets
          # `formatter = { command = "prettier", args = ["--stdin-filepath", "%{buffer_name}"] }`
          # in its own .helix/languages.toml.
          prettier
          ruff
          taplo
          markdown-oxide # wikilinks/backlinks for the ~/Notes Obsidian vault
          lldb # lldb-dap
          delve # dlv
        ];

        settings = lib.mkMerge [
          {
            editor = {
              scrolloff = 10;
              cursorline = true;
              bufferline = "multiple";
              color-modes = true;
              indent-guides.render = true;
              soft-wrap.enable = true;
              whitespace = {
                render = {
                  tab = "all";
                  space = "none";
                };
                characters.tab = "→";
              };
              # Pickers show dotfiles, matching the old telescope `hidden = true`.
              file-picker.hidden = true;
              lsp.display-progress-messages = true;
            };
          }
          # WSL has no Stylix, so no generated theme: the built-in
          # kanagawa-dragon keeps it on the same palette as the desktop, with
          # the background dropped to match the transparent Stylix theme.
          (lib.mkIf (!(config.stylix.enable or false)) { theme = "kanagawa-dragon-transparent"; })
        ];

        themes = lib.mkIf (!(config.stylix.enable or false)) {
          kanagawa-dragon-transparent = {
            inherits = "kanagawa-dragon";
            "ui.background" = { };
          };
        };

        languages = {
          language-server = {
            nixd.config.nixd.formatting.command = [ "nixfmt" ];
            clangd.args = [
              "--background-index"
              "--clang-tidy"
              "--header-insertion=never"
            ];
            oxlint = {
              command = "oxlint";
              args = [ "--lsp" ];
            };
            oxfmt = {
              command = "oxfmt";
              args = [ "--lsp" ];
            };
          };

          language = [
            {
              name = "nix";
              language-servers = [ "nixd" ];
              auto-format = true; # nixd runs nixfmt
            }
            # Helix's defaults list servers that are not installed on purpose
            # (nil beside nixd, marksman beside markdown-oxide, and so on); a
            # missing binary fails on every buffer, so name one server each.
            {
              name = "markdown";
              language-servers = [ "markdown-oxide" ];
            }
            {
              name = "python";
              language-servers = [ "ruff" ];
            }
            {
              name = "toml";
              language-servers = [ "taplo" ];
            }
            {
              name = "yaml";
              language-servers = [ "yaml-language-server" ];
            }
            {
              name = "html";
              language-servers = [ "vscode-html-language-server" ];
            }
          ]
          # oxlint adds diagnostics and fixes beside typescript-language-server;
          # oxfmt owns formatting, so tsserver's formatter is switched off.
          ++
            map
              (name: {
                inherit name;
                auto-format = true;
                language-servers = [
                  {
                    name = "typescript-language-server";
                    except-features = [ "format" ];
                  }
                  "oxlint"
                  {
                    name = "oxfmt";
                    only-features = [ "format" ];
                  }
                ];
              })
              [
                "javascript"
                "jsx"
                "typescript"
                "tsx"
              ];
        };
      };

      # Stylix supplies gui.theme; lazygit reads this same config.
      config.programs.lazygit = {
        enable = true;
        settings.git.diffRenderers = [ { command = "delta --{{colorScheme}} --paging=never"; } ];
      };

      # Generated git credential helper tracks the current gh store path,
      # unlike `gh auth setup-git`, which pins one that gets garbage-collected.
      config.programs.gh = {
        enable = true;
        settings.aliases.co = "pr checkout";
      };
    };
}
