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
          # WSL has no Stylix, so load the same transparent Gruvbox Paper theme
          # directly instead of Stylix's generated themes/stylix.toml.
          (lib.mkIf (!(config.stylix.enable or false)) { theme = "gruvbox-paper"; })
        ];

        themes = lib.mkIf (!(config.stylix.enable or false)) {
          gruvbox-paper = builtins.fromTOML (builtins.readFile ./gruvbox-paper.toml);
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
        settings.git.diffRenderers = [ { command = "delta --{{colorScheme}} --paging=never -s"; } ];
      };

      # omp paints with its own 67 color tokens and never asks the terminal for
      # its palette, so Stylix cannot reach it the way it reaches helix or zed.
      # Generate a theme from the same base16 colors; the file name is the
      # theme ID that `theme.dark` selects (`omp config set theme.dark stylix`).
      # `terminal` is for hosts that paint the terminal themselves (Tern);
      # omp's TUI always draws on the terminal's own background.
      config.home.file.".omp/agent/themes/stylix.json" = lib.mkIf (config.stylix.enable or false) {
        text = builtins.toJSON (
          let
            c = config.lib.stylix.colors.withHashtag;
          in
          {
            name = "stylix";
            vars = {
              bg0 = c.base00;
              bg1 = c.base01;
              bg2 = c.base02;
              fg3 = c.base03;
              fg4 = c.base04;
              fg5 = c.base05;
              fg7 = c.base07;
              red = c.base08;
              orange = c.base09;
              yellow = c.base0A;
              green = c.base0B;
              cyan = c.base0C;
              blue = c.base0D;
              purple = c.base0E;
              brown = c.base0F;
            };
            colors = {
              accent = "yellow";
              border = "bg2";
              borderAccent = "blue";
              borderMuted = "bg1";
              success = "green";
              error = "red";
              warning = "orange";
              muted = "fg4";
              dim = "fg3";
              text = "fg5";
              thinkingText = "fg3";
              selectedBg = "bg2";
              userMessageBg = "bg1";
              userMessageText = "fg5";
              customMessageBg = "bg1";
              customMessageText = "fg5";
              customMessageLabel = "purple";
              toolPendingBg = "bg1";
              toolSuccessBg = "bg1";
              toolErrorBg = "bg1";
              toolTitle = "fg5";
              toolOutput = "fg4";
              mdHeading = "yellow";
              mdLink = "blue";
              mdLinkUrl = "fg3";
              mdCode = "purple";
              mdCodeBlock = "cyan";
              mdCodeBlockBorder = "fg3";
              mdQuote = "fg4";
              mdQuoteBorder = "fg3";
              mdHr = "bg2";
              mdListBullet = "yellow";
              toolDiffAdded = "green";
              toolDiffRemoved = "red";
              toolDiffContext = "fg4";
              link = "blue";
              syntaxComment = "fg3";
              syntaxKeyword = "purple";
              syntaxFunction = "blue";
              syntaxVariable = "fg5";
              syntaxString = "green";
              syntaxNumber = "orange";
              syntaxType = "yellow";
              syntaxOperator = "fg5";
              syntaxPunctuation = "fg4";
              thinkingOff = "bg2";
              thinkingMinimal = "fg3";
              thinkingLow = "cyan";
              thinkingMedium = "blue";
              thinkingHigh = "purple";
              thinkingXhigh = "brown";
              bashMode = "cyan";
              statusLineBg = "bg1";
              statusLineSep = "bg2";
              statusLineModel = "purple";
              statusLinePath = "cyan";
              statusLineGitClean = "green";
              statusLineGitDirty = "yellow";
              statusLineContext = "blue";
              statusLineSpend = "cyan";
              statusLineStaged = "green";
              statusLineDirty = "yellow";
              statusLineUntracked = "cyan";
              statusLineOutput = "brown";
              statusLineCost = "brown";
              statusLineSubagents = "yellow";
              pythonMode = "yellow";
            };
            terminal = {
              background = "bg0";
              foreground = "fg5";
              chrome = "bg1";
              widget = "bg2";
              ansi = [
                "bg0"
                "red"
                "green"
                "yellow"
                "blue"
                "purple"
                "cyan"
                "fg5"
                "fg3"
                "red"
                "green"
                "yellow"
                "blue"
                "purple"
                "cyan"
                "fg7"
              ];
            };
          }
        );
      };

      # Rex (the macOS terminal multiplexer app) keeps its palette in its own
      # GUI theme store, so Stylix cannot write it. Settings > Theme > Import
      # Theme File reads a Ghostty theme: this one, generated from the same
      # base16 colors, with every value '#'-prefixed because Rex parses hex
      # as "#RRGGBB" or "RRGGBB". Import once; Rex then owns the palette.
      config.home.file.".config/rex/stylix.ghostty" = lib.mkIf (config.stylix.enable or false) {
        text =
          let
            c = config.lib.stylix.colors.withHashtag;
            ansi = [
              "base00" "base08" "base0B" "base0A" "base0D" "base0E" "base0C" "base05"
              "base03" "base08" "base0B" "base0A" "base0D" "base0E" "base0C" "base07"
            ];
          in
          ''
            background = ${c.base00}
            foreground = ${c.base05}
            cursor-color = ${c.base05}
            selection-background = ${c.base02}
            selection-foreground = ${c.base05}
          ''
          + lib.concatStrings (
            lib.imap0 (i: name: "palette = ${toString i}=${c.${name}}\n") ansi
          );
      };

      # Generated git credential helper tracks the current gh store path,
      # unlike `gh auth setup-git`, which pins one that gets garbage-collected.
      config.programs.gh = {
        enable = true;
        settings.aliases.co = "pr checkout";
      };
    };
}
