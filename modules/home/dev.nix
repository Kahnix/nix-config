{ inputs, ... }:
{
  # claude-code ships under Anthropic's proprietary licence.
  unfreePackages = [ "claude-code" ];

  flake.modules.homeManager.dev =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
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
          # nixpkgs pins a stale bun-deps hash for opencode 2.2.5, so the FOD
          # never matches and the whole system build fails. Re-pin it to what the
          # derivation actually produces.
          # shortcut: local hash override, drop it once pkgs/by-name/op/opencode
          # ships a matching node_modules outputHash.
          (opencode.overrideAttrs (prev: {
            node_modules = prev.node_modules.overrideAttrs (_: {
              outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            });
          }))
          omp
          herdr
          # opencode's Claude Agent provider shells out to this binary.
          claude-code
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

        # Sets EDITOR and VISUAL to hx.
        defaultEditor = true;

        # hx only finds language servers on PATH, so they are installed beside
        # it rather than fetched by an editor plugin.
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
              # Pickers show dotfiles.
              file-picker.hidden = true;
              lsp.display-progress-messages = true;
              # hx paints block cursors itself as an inverted cell and hides
              # the terminal cursor, so the terminal's own cursor rendering
              # (animation, blink) only applies to bar/underline shapes.
              cursor-shape.insert = "bar";
            };
            # Ctrl-e: pick a file in yazi, starting at the current buffer, and
            # open it. yazi takes over the terminal, so hx's alternate screen
            # and bracketed paste are re-enabled before redrawing.
            keys.normal.C-e = [
              ":sh rm -f /tmp/hx-yazi-chooser"
              ":insert-output yazi %{buffer_name} --chooser-file=/tmp/hx-yazi-chooser"
              ":insert-output printf '\\033[?1049h\\033[?2004h' > /dev/tty"
              ":open %sh{cat /tmp/hx-yazi-chooser}"
              ":redraw"
            ];
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
            # Option completion (programs.git.<tab>) comes from this host's own
            # configuration in the live flake checkout, not a store copy.
            nixd = {
              args = [ "--semantic-tokens=true" ];
              config.nixd =
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
                  formatting.command = [ "nixfmt" ];
                  nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
                  options = {
                    ${if pkgs.stdenv.hostPlatform.isDarwin then "nix-darwin" else "nixos"}.expr = "${system}.options";
                    home-manager.expr = "${system}.options.home-manager.users.type.getSubOptions [ ]";
                  };
                };
            };
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
