{
  config,
  lib,
  pkgs,
  inputs,
  username,
  homeDirectory,
  ...
}:

let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  home.packages =
    (with pkgs; [
      neovim
      tmux
      gh
      git-lfs
      ripgrep
      fd
      jq
      bat
      eza
      fastfetch
      unzip
      tree
      nodejs
      pnpm
      bun
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
      unstable.devenv
      nixfmt
      codex
      opencode
    ])
    ++ lib.optionals pkgs.stdenv.isDarwin (
      with pkgs;
      [
        jdk17
        watchman
      ]
    );

  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    ANDROID_HOME = "${homeDirectory}/Library/Android/sdk";
    ANDROID_SDK_ROOT = "${homeDirectory}/Library/Android/sdk";
    JAVA_HOME = pkgs.jdk17.home;
  };

  home.sessionPath = lib.optionals pkgs.stdenv.isDarwin [
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

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "";
    };

    initContent = ''
      if [[ -z "$TMUX" && -n "$PS1" ]]; then
        exec tmux new-session -A -s main
      fi
    '';

    shellAliases = {
      ll = "eza -la";
      gs = "git status";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      rebuild = "sudo nixos-rebuild switch --flake ~/nix-config#wsl";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#macbook-pro-m4";
    };
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-s";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-save 'S'
          set -g @resurrect-restore 'R'
        '';
      }
    ];
    extraConfig = ''
      set -g mouse on
      set -g history-limit 10000
      set -g status-interval 5
      set -g status-left-length 40
      set -g status-right-length 90
      set -g status-right "#[fg=black]%Y-%m-%d %H:%M #[fg=black]#(whoami)"

      # Keep new panes and windows in the active pane's working directory.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      command_timeout = 3000;
      scan_timeout = 50;
      format = "$all\n$username$hostname$directory";
      character = {
        success_symbol = "[](bold green) ";
        error_symbol = "[✗](bold red) ";
      };
    };
  };

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
    enableZshIntegration = true;
    enableNushellIntegration = false;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
    ];
    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always {}'"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
