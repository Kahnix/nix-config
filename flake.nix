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

    # Add this later when you actually set up the Mac.
    # darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    # darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... }@inputs:
  let
    username = "kacper";

    mkSystem = import ./lib/mksystem.nix {
      inherit inputs username;
    };
  in {
    nixosConfigurations.wsl = mkSystem {
      name = "wsl";
      system = "x86_64-linux";
      wsl = true;
    };
  };
}