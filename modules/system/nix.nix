{ config, inputs, ... }:
let
  # Shared by NixOS and nix-darwin; both expose these options.
  nixSettings = {
    nixpkgs = {
      config.allowUnfreePackages = config.unfreePackages;
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
        # chaotic-cx/nyx (see modules/hardware/kernel.nix). The third-party
        # attic cache that used to be listed here (attic.xuyh0120.win/lantian)
        # is down after a server compromise (xddxdd/nix-cachyos-kernel#110),
        # and its key is gone so nothing it serves can be trusted or substituted.
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://nyx-cache.chaotic.cx/"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        ];
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
