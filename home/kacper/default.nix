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

  home.packages = with pkgs; [
    neovim
    tmux

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
    unstable.devenv
    nixfmt
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
