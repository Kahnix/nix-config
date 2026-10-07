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
          (_: {
            CARGO_PROFILE_RELEASE_LTO = "thin";
            CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
          });
    in
    {
      options.my.omp.waylandScreencast = lib.mkEnableOption "omp's PipeWire-backed Wayland capture addon";

      config.home.packages =
        (with pkgs; [
          neovim
          tree-sitter
          gh
          git-lfs
          ripgrep
          fd
          jq
          bat
          eza
          unzip
          tree
          nodejs
          pnpm
          inputs.bunnix.packages.${system}.v1_3_14
          deno
          go
          rustup
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
          lazygit
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
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.gcc ];
    };
}
