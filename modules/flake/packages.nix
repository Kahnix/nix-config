{
  config,
  inputs,
  lib,
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

      # Everything in pkgs/ targets the Linux desktop.
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ../../pkgs { inherit pkgs; });

      # `nix fmt` formats the whole tree with nixfmt.
      formatter = pkgs.nixfmt-tree;
    };
}
