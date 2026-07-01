{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";

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

    unzip
    tree
    nodejs
    pnpm
    rustup
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
      rebuild = "sudo nixos-rebuild switch --flake ~/nix-config#wsl";
    };
  };

  programs.starship.enable = true;

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
