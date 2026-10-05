{
  lib,
  pkgs,
  inputs,
  username,
  homeDirectory,
  isWSL ? false,
  isNixOS ? false,
  ...
}:

{
  imports = [
    ./darwin-desktop.nix
    ./ghostty.nix
    ./hyprland.nix
    ./linux-desktop.nix
    ./quickshell.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;

  home.packages =
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
      inputs.bunnix.packages.${pkgs.stdenv.hostPlatform.system}.v1_3_14
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
      nh
      nix-index
      nix-init
      nix-inspect
      nix-melt
      nix-output-monitor
      nix-search-tv
      nix-tree
      nvd
      opencode
      # Only the Linux desktop needs the PipeWire-backed Wayland capture addon.
      (
        (inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp.override {
          withWaylandScreencast = isNixOS;
        }).overrideAttrs
          (_: {
            CARGO_PROFILE_RELEASE_LTO = "thin";
            CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
          })
      )
      herdr
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        gcc
      ]
    )
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
      with pkgs;
      [
        jdk17
        watchman
      ]
    );

  home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    ANDROID_HOME = "${homeDirectory}/Library/Android/sdk";
    ANDROID_SDK_ROOT = "${homeDirectory}/Library/Android/sdk";
    JAVA_HOME = pkgs.jdk17.home;
  };

  home.sessionPath = [
    "${homeDirectory}/.local/bin"
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    "${homeDirectory}/Library/Android/sdk/emulator"
    "${homeDirectory}/Library/Android/sdk/platform-tools"
    "${homeDirectory}/Library/Android/sdk/cmdline-tools/latest/bin"
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "kahnix";
        email = "kacperdev@gmail.com";
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

    shellAliases = {
      ll = "eza -la";
      gs = "git status";
      lg = "lazygit";
      bt = "btop";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      rebuild =
        if isWSL then
          "sudo nixos-rebuild switch --flake ~/nix-config#wsl"
        else
          "sudo nixos-rebuild switch --flake ~/nix-config#nixos";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#macbook-pro-m4";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = false;

    settings = {
      command_timeout = 3000;
      scan_timeout = 50;
      format = "$all$username$hostname$directory";
      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[×](bold red) ";
      };
    };
  };

  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    enableFishIntegration = true;
    enableNushellIntegration = false;
    enableZshIntegration = false;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];

    fileWidget = {
      options = [ "--preview 'bat --style=numbers --color=always --line-range :200 {}'" ];
      command = "fd --type f --hidden --follow --exclude .git";
    };

    changeDirWidget = {
      options = [ "--preview 'eza --tree --level=2 --color=always {}'" ];
      command = "fd --type d --hidden --follow --exclude .git";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = false;
    enableZshIntegration = false;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = false;
    silent = true;
    nix-direnv.enable = true;
  };
}
