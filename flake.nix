{
  description = "Kacper's NixOS, WSL, and dev configs";

  inputs = {
    # Main package set for the whole system.
    # Track the rolling upstream package set across all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NixOS on WSL.
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Cache-friendly performance kernel used by the desktop host.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # User-level config: shell, git, nvim, tmux, packages.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Desktop shell: bar, launcher, notifications, lock screen, and wallpaper.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Login screen matching the Noctalia desktop.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Portable wrapper derivations (typed Nix config instead of raw dotfiles).
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration tracks the same unstable package set.
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # herdr
    herdr.url = "github:herdrdev/herdr/master";

    # OMP coding agent.
    omp.url = "github:can1357/oh-my-pi";

    # Bun2nix
    bunnix.url = "github:aster-void/bunnix";
    bunnix.inputs.nixpkgs.follows = "nixpkgs";

    # Stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen is not in nixpkgs; use the maintained community packaging.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

  };

  outputs =
    { nixpkgs, ... }@inputs:

    # Change these to your own username and home directory.
    let
      wslUsername = "kacper";
      darwinUsername = "kacperdaniel";
      nixosUsername = "kacper";

      mkSystem = import ./lib/mksystem.nix {
        inherit inputs;
      };
    in
    {
      nixosConfigurations.wsl = mkSystem {
        name = "wsl";
        system = "x86_64-linux";
        username = wslUsername;
        homeDirectory = "/home/${wslUsername}";
        wsl = true;
      };

      nixosConfigurations.nixos = mkSystem {
        name = "nixos";
        system = "x86_64-linux";
        username = nixosUsername;
        homeDirectory = "/home/${nixosUsername}";
        theming = true;
      };

      darwinConfigurations."macbook-pro-m4" = mkSystem {
        name = "darwin";
        system = "aarch64-darwin";
        username = darwinUsername;
        homeDirectory = "/Users/${darwinUsername}";
        darwin = true;
        theming = true;
      };
    };
}
