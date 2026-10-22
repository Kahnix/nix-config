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
          neovim
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

      # Stylix supplies gui.theme; lazygit.nvim reads this same config.
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
