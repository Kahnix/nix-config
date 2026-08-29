{ inputs }:

{
  name,
  system,
  username,
  homeDirectory,
  darwin ? false,
  wsl ? false,
}:

let
  lib = inputs.nixpkgs.lib;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  homeManagerModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;
in
systemFunc {
  inherit system;

  specialArgs = {
    inherit
      inputs
      system
      username
      homeDirectory
      ;
    isDarwin = darwin;
    isWSL = wsl;
    isNixOS = !darwin && !wsl;
  };

  modules = [
    ../modules/unfree-packages.nix
    # OMP publishes builds here for every configured platform.  Configure the
    # cache at the daemon level because a nested flake's nixConfig is not
    # inherited by this configuration.
    {
      nix.settings = {
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    }
    {
      nixpkgs.overlays = [
        (import ../overlays/nodejs-24-darwin-fd-tracking.nix)
      ];
    }
    ../hosts/${name}
    homeManagerModule
  ]
  ++ lib.optionals wsl [
    inputs.nixos-wsl.nixosModules.default
  ];
}
