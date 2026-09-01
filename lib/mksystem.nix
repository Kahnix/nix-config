{ inputs }:

{
  name,
  system,
  username,
  homeDirectory,
  darwin ? false,
  wsl ? false,
  theming ? false,
}:

let
  lib = inputs.nixpkgs.lib;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  homeManagerModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;
  stylixModule =
    if darwin then inputs.stylix.darwinModules.stylix else inputs.stylix.nixosModules.stylix;
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
    {
      nixpkgs.overlays = [
        (import ../overlays/nodejs-24-darwin-fd-tracking.nix)
      ];
    }
    ../hosts/${name}
    homeManagerModule
  ]
  ++ lib.optionals theming [
    stylixModule
    ../modules/theme.nix
  ]
  ++ lib.optionals wsl [
    inputs.nixos-wsl.nixosModules.default
  ];
}
