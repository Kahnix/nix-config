{ inputs, ... }:
{
  flake.modules.nixos.kernel =
    { pkgs, ... }:
    {
      # CachyOS kernels are not in nixpkgs, so cache.nixos.org never has them.
      # Take the kernel from chaotic-cx/nyx, whose CI builds the same CachyOS
      # patches and publishes them to nyx-cache.chaotic.cx (added as a
      # substituter in modules/system/nix.nix). Nyx's own locked nixpkgs must
      # stay in place: its cache key is that derivation, and overriding nixpkgs
      # here would turn every bump back into a source build.
      #
      # -eevdf is CachyOS's default scheduler without LTO, i.e. what the old
      # xddxdd linux-cachyos-latest was. The package set inherits the kernel's
      # stdenv from nyx's nixpkgs (no unfree policy, different compiler), so
      # point the module set back at our stdenv: nvidia and friends must obey
      # this config's unfree list. nixpkgs still builds those modules locally,
      # which is why the nvidia module compiles per kernel bump.
      boot.kernelPackages =
        (pkgs.linuxPackagesFor inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.linux_cachyos-rc)
        .extend
          (_final: _prev: { stdenv = pkgs.stdenv; });
    };
}
