{
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {
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

      # Keyboard-first file manager. Stylix writes the base16 theme into
      # theme.toml; the extra packages give yazi previews for video, PDF and
      # archives. Its default `open` opener is xdg-open on Linux and `open` on
      # macOS, so the platform's handlers decide what a file opens with.
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        # yazi's built-in previewers shell out to these: ffmpeg/ffprobe for video
        # thumbnails, pdftoppm for PDF, 7zz for archives, magick for exotic images
        # (avif/heif/jxl) and font files, file(1) for MIME spotting.
        extraPackages = with pkgs; [
          _7zz
          ffmpeg
          exiftool
          file
          imagemagick
          poppler-utils
        ];
        settings = {
          mgr = {
            show_hidden = true;
            sort_dir_first = true;
          };

          # Enter/o on text and code files runs this (yazi's `open` rules send
          # text/* and code types to the `edit` opener). Spelled out rather than
          # relying on $EDITOR: GUI sessions inherit their environment at login, so
          # a session started before EDITOR changed keeps the old value for every
          # spawn. `block = true` hands the terminal to hx and returns to yazi
          # on quit.
          opener.edit = [
            {
              run = "hx %s";
              block = true;
              desc = "Helix";
            }
          ];
        };
      };
    };
}
