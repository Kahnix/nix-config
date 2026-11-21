{
  description = "Kacper's NixOS, WSL, and dev configs";

  inputs = {
    # Shared package set for all hosts. nixos-unstable (not nixpkgs-unstable):
    # the channel only advances once Hydra has built and tested the release
    # jobs, so heavy packages (zed, telegram, ...) are in cache.nixos.org.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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

    # Official Jagex Launcher (Linux beta); own package, Kahnix/jagex-launcher-nix.
    jagex-launcher = {
      url = "github:Kahnix/jagex-launcher-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CachyOS sysctl/udev/systemd tuning as a NixOS module; areas enabled in modules/system/cachyos-settings.nix.
    cachyos-settings-nix = {
      url = "github:Daaboulex/cachyos-settings-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI agent skills, shared by Zed, OpenCode, Claude Code and Antigravity.
    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
    taste-skill = {
      url = "github:Leonxlnx/taste-skill";
      flake = false;
    };
    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    supabase-skills = {
      url = "github:supabase/agent-skills";
      flake = false;
    };
    # Oxlint rules that reject low-evidence TypeScript, by Cloudflare's
    # Dillon Mulroy. The skill vendors the plugin into a project.
    anti-slop = {
      url = "git+https://github.com/dmmulroy/anti-slop";
      flake = false;
    };

    # Hex voice agent for opencode
    opencode-hex = {
      url = "github:anomalyco/hex";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI plan quotas (Claude, Antigravity, OpenCode Go): CLI + TUI built from
    # source on Linux; macOS uses the release bundle for its menu-bar app.
    ai-usagebar = {
      url = "github:akitaonrails/ai-usagebar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Outputs are assembled by flake-parts from every module under ./modules.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";

    # Rex terminal multiplexer server/CLI (prebuilt release binaries).
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Dendritic layout: every .nix file under ./modules is a flake-parts module.
  # Feature files contribute flake.modules.{nixos,darwin,homeManager}.<name>;
  # files under ./modules/hosts compose those into system configurations.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
