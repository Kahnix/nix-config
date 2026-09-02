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
    ./linux-desktop.nix
    inputs.omp.homeManagerModules.default
  ]
  ++ lib.optionals isNixOS [ inputs.noctalia.homeModules.default ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.11";

  programs.home-manager.enable = true;
  # Herdr has no Stylix target. Keep its token overrides aligned with the
  # Kanagawa Dragon Base16 palette selected in modules/theme.nix.
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    # Herdr's closest built-in foundation; Dragon is applied through its tokens.
    name = "kanagawa"
    auto_switch = false

    [theme.custom]
    accent = "#8ba4b0"
    panel_bg = "#181616"
    sidebar_bg = "#181616"
    active_row_bg = "#282727"
    selection_bg = "#393836"
    surface0 = "#282727"
    surface1 = "#393836"
    surface_dim = "#181616"
    overlay0 = "#625e5a"
    overlay1 = "#737c73"
    text = "#c5c9c5"
    subtext0 = "#737c73"
    mauve = "#a292a3"
    green = "#8a9a7b"
    yellow = "#c4b28a"
    red = "#c4746e"
    blue = "#8ba4b0"
    teal = "#8ea4a2"
    peach = "#b6927b"

    [ui]
    agent_panel_sort = "priority"
    status_indicators = "symbols"

    [ui.sidebar.agents]
    rows = [
      ["state_icon", "agent", "state_text"],
      ["terminal_title_stripped"],
      ["workspace", "tab"],
    ]

  '';

  # omp: disabled via Nix — upstream oh-my-pi's bun2nix lockfile is missing a
  # pinned hash for @bgotink/kdl@0.4.0, so the sandboxed build always tries to
  # hit registry.npmjs.org and fails. Installed instead via the official
  # installer (curl -fsSL https://omp.sh/install | sh). Re-enable once
  # upstream's lockfile is fixed.
  programs.omp.enable = false;

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
      claude-code
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
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

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

      logo = {
        source = if pkgs.stdenv.hostPlatform.isDarwin then "macOS" else "NixOS";
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
        }
      ];
    };
  };

  programs.btop = {
    enable = true;
    settings = {
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
