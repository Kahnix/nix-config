{
  config,
  inputs,
  ...
}:
let
  unfreePackages = config.unfreePackages;
in
{
  flake.overlays.default = final: _prev: import ../../pkgs { pkgs = final; };

  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePackages = unfreePackages;
      };

      # Everything in pkgs/ targets the Linux desktop, except winvm, which also
      # runs on the Apple Silicon Mac (`nix run .#winvm`).
      packages =
        let
          all = import ../../pkgs { inherit pkgs; };
        in
        if pkgs.stdenv.hostPlatform.isLinux then all else { inherit (all) winvm; };

      # `nix fmt` formats the whole tree with nixfmt.
      formatter = pkgs.nixfmt-tree;
    };
}
