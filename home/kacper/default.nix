{ config, pkgs, inputs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    neovim
    tmux

    ripgrep
    fd
    fzf
    jq
    bat
    eza
    zoxide

    unzip
    tree
  ];

  programs.git = {
    enable = true;
    userName = "Kacper";
    userEmail = "kacperdev@gmail.com";
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      ll = "eza -la";
      gs = "git status";
      rebuild = "sudo nixos-rebuild switch --flake ~/code/nixos-config#wsl";
    };
  };

  programs.starship.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}