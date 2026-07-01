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

    # User-level config: shell, git, nvim, tmux, packages.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS system configuration.
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... }@inputs:

  # Change these to your own username and home directory.
  let
    wslUsername = "kacper";
    darwinUsername = "kacperdaniel";

    mkSystem = import ./lib/mksystem.nix {
      inherit inputs;
    };
  in {
    nixosConfigurations.wsl = mkSystem {
      name = "wsl";
      system = "x86_64-linux";
      username = wslUsername;
      homeDirectory = "/home/${wslUsername}";
      wsl = true;
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
