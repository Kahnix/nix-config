{ config, inputs, ... }:
let
  # Shared by NixOS and nix-darwin; both expose these options.
  nixSettings = {
    nixpkgs = {
      config.allowUnfreePackages = config.unfreePackages;
      # gtk2 is flagged `broken` upstream as a removal notice (final release
      # 2.24.33, December 2020; removal scheduled for NixOS 27.05), and current
      # nixpkgs refuses to *evaluate* broken packages. It still evaluates and
      # builds fine, so allowing it is a warning, not a lie. Nothing here uses
      # gtk2 directly: lutris' FHS rootfs pulls it in transitively. Drop this
      # once lutris no longer drags in gtk2, or start migrating then.
      config.problems.handlers."gtk+".broken = "warn";
      overlays = [ inputs.self.overlays.default ];
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Substitution is per store path: Nix asks each cache for a narinfo for
        # every output it lacks, and only accepts a hit whose derivation hash
        # matches, so extra caches can only save builds, never change them.
        # cache.nixos.org is the NixOS default; nix-community covers that org's
        # flake outputs; nyx-cache carries the CachyOS kernels from
        # chaotic-cx/nyx (see modules/hardware/kernel.nix).
        # The third-party attic cache that used to be listed here
        # (attic.xuyh0120.win/lantian) is down after a server compromise
        # (xddxdd/nix-cachyos-kernel#110),
        # and its key is gone so nothing it serves can be trusted or substituted.
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://nyx-cache.chaotic.cx/"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        ];
        # 16 cores but 15 GB of RAM: 16 concurrent heavy builds (zed's Rust
        # workspace, Qt apps) spend their time in swap.
        max-jobs = 6;
        # One failing derivation must not discard the builds that already
        # finished; the rest of the system still gets built and activated.
        keep-going = true;
      };
      # Weekly: drop generations older than two weeks, then dedupe the store.
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };
      optimise.automatic = true;
    };

    system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  };
in
{
  flake.modules.nixos.nix = nixSettings;
  flake.modules.darwin.nix = nixSettings;
}
