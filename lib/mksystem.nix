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
  systemFunc =
    if darwin then
      inputs.darwin.lib.darwinSystem
    else
      inputs.nixpkgs.lib.nixosSystem;
  homeManagerModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;
in
systemFunc {
  inherit system;

  specialArgs = {
    inherit inputs system username homeDirectory;
    isDarwin = darwin;
    isWSL = wsl;
  };

  modules =
    [
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
