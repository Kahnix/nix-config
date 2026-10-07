{ config, inputs, ... }:
let
  # Shared by NixOS and nix-darwin; both expose these options.
  nixSettings = {
    nixpkgs = {
      config.allowUnfreePackages = config.unfreePackages;
      overlays = [ inputs.self.overlays.default ];
    };

    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
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
