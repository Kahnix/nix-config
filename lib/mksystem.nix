{ inputs, username }:

{ name, system, wsl ? false }:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs username;
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