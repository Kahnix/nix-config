{
  flake.modules.homeManager.shell = {
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

      # Each host adds a `rebuild` alias for its own configuration.
      shellAliases = {
        ll = "eza -la";
        gs = "git status";
        lg = "lazygit";
        bt = "btop";
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
  };
}
