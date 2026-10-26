{
  description = "Kacper's NixOS, WSL, and dev configs";

  inputs = {
    # Shared rolling package set for all hosts.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NixOS on WSL.
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # CachyOS kernels. xddxdd's cache went offline after a server compromise
    # (xddxdd/nix-cachyos-kernel#110), so this tracks chaotic-cx's build of the
    # same kernels, which publishes substitutes at nyx-cache.chaotic.cx.
    # Its nixpkgs is deliberately not overridden: the cache key is the
    # derivation built by this flake's own lock.
    chaotic.url = "github:chaotic-cx/nyx/main";

    # User-level config: shell, git, helix, tmux, packages.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS system configuration tracks the same unstable package set.
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Bun2nix
    bunnix.url = "github:aster-void/bunnix";
    bunnix.inputs.nixpkgs.follows = "nixpkgs";

    # Stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nerd Font patched Berkeley Mono. Private: Berkeley Mono is a paid, per-person font.
    # Fetched over SSH, so evaluating needs a GitHub key with access to the repo.
    berkeley-mono-nerd = {
      url = "git+ssh://git@github.com/Kahnix/berkeley-mono-nerd";
      flake = false;
    };

    # Shared coding agent; the desktop enables Wayland capture in Home Manager.
    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
    };

    # Official Jagex Launcher (Linux beta); own package, Kahnix/jagex-launcher-nix.
    jagex-launcher = {
      url = "github:Kahnix/jagex-launcher-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Outputs are assembled by flake-parts from every module under ./modules.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
  };

  # Dendritic layout: every .nix file under ./modules is a flake-parts module.
  # Feature files contribute flake.modules.{nixos,darwin,homeManager}.<name>;
  # files under ./modules/hosts compose those into system configurations.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
