{
  description = "Kacper's NixOS, WSL, and dev configs";

  inputs = {
    # Main package set for the whole system.
    # Stable is calmer than unstable for system config.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Optional: later use this for newer tools only.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

    # macOS system configuration.
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # herdr
    herdr.url = "github:herdrdev/herdr/v0.8.0";

    # OMP coding agent.
    omp.url = "github:can1357/oh-my-pi";

    # Kacper's Neovim config is linked into ~/.config/nvim by Home Manager.
    nvim-config = {
      url = "github:Kahnix/nvim-config";
      flake = false;
    };

    # Zen is not in nixpkgs; use the maintained community packaging.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Proprietary, locally installed font; its contents stay outside this repository.
    berkeley-mono = {
      url = "path:/home/kacper/.local/share/fonts/BerkeleyMono";
      flake = false;
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
      };

      darwinConfigurations."macbook-pro-m4" = mkSystem {
        name = "darwin";
        system = "aarch64-darwin";
        username = darwinUsername;
        homeDirectory = "/Users/${darwinUsername}";
        darwin = true;
      };
    };
}
