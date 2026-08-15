{
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
  imports = [ ./darwin-desktop.nix ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

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
      claude-code
      unstable.opencode
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ])
    ++ lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        gcc
      ]
    )
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

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

      logo = {
        source = if pkgs.stdenv.isDarwin then "macOS" else "NixOS";
        color = {
          "1" = "#7E9CD8";
          "2" = "#98BB6C";
        };
        padding = {
          top = 1;
          right = 4;
        };
      };

      display = {
        separator = "    ";
        color = {
          keys = "#98BB6C";
          output = "#C8C093";
          separator = "#7E9CD8";
        };
        key = {
          width = 2;
          type = "string";
        };
        percent.color = {
          green = "#98BB6C";
          yellow = "#E6C384";
          red = "#E46876";
        };
      };

      modules = [
        {
          type = "custom";
          format = "╭────────────── hardware ──────────────╮";
          outputColor = "#7E9CD8";
        }
        {
          type = "host";
          key = "󰌢";
          format = "{name}";
        }
        {
          type = "cpu";
          key = "";
          format = "{name} ({cores-logical} cores)";
        }
        {
          type = "gpu";
          key = "󰢮";
          format = "{name}";
        }
        {
          type = "memory";
          key = "";
          format = "{used} / {total} ({percentage})";
        }
        {
          type = "disk";
          key = "";
          format = "{size-used} / {size-total} ({size-percentage})";
        }
        {
          type = "display";
          key = "󰍹";
          format = "{width}x{height} @ {refresh-rate} Hz";
        }
        {
          type = "custom";
          format = "╰─────────────────────────────────────╯";
          outputColor = "#7E9CD8";
        }
        "break"
        {
          type = "custom";
          format = "╭────────────── software ──────────────╮";
          outputColor = "#7E9CD8";
        }
        {
          type = "os";
          key = "";
          format = "{pretty-name} {arch}";
        }
        {
          type = "kernel";
          key = "";
          format = "{sysname} {release}";
        }
        {
          type = "shell";
          key = "";
        }
        {
          type = "wm";
          key = "";
        }
        {
          type = "uptime";
          key = "󰥔";
        }
        {
          type = "custom";
          format = "╰─────────────────────────────────────╯";
          outputColor = "#7E9CD8";
        }
      ];
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "kanagawa-wave";
      theme_background = false;
      truecolor = true;
      vim_keys = true;
      rounded_corners = true;

      shown_boxes = "cpu mem proc";
      update_ms = 2000;
      graph_symbol = "braille";

      cpu_single_graph = true;
      show_gpu_info = "Off";
      show_uptime = false;
      show_cpu_watts = false;
      show_coretemp = false;
      show_cpu_freq = false;
      clock_format = "";

      mem_graphs = false;
      show_swap = false;
      swap_disk = false;
      show_disks = false;

      proc_sorting = "cpu lazy";
      proc_colors = true;
      proc_gradient = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = false;

      show_battery = false;
    };
  };
  xdg.configFile."btop/btop.conf".force = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

    shellAliases = {
      ll = "eza -la";
      gs = "git status";
      lg = "lazygit";
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
    enableFishIntegration = true;
    enableZshIntegration = false;

    settings = {
      command_timeout = 3000;
      scan_timeout = 50;
      format = "$all$username$hostname$directory";
      character = {
        success_symbol = "[](bold green) ";
        error_symbol = "[✗](bold red) ";
      };
    };
  };

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
    enableFishIntegration = true;
    enableNushellIntegration = false;
    enableZshIntegration = false;

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
