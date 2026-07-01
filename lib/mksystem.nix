{ inputs, username }:

{ name, system, wsl ? false }:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs username;
    isWSL = wsl;
  };

  modules =
    [
      ../hosts/${name}
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ inputs.nixpkgs.lib.optionals wsl [
      inputs.nixos-wsl.nixosModules.default
    ];
}