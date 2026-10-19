{ inputs, ... }:
{
  flake.modules.nixos.kernel =
    { pkgs, ... }:
    {
      # Pinned evaluates the kernel with the flake's own locked nixpkgs, so the
      # derivation changes only when this input is bumped, not whenever nixpkgs
      # moves. Its CachyOS-patched kernels are not in nixpkgs, so cache.nixos.org
      # never has them; the flake's own attic cache is offline after the server
      # compromise (xddxdd/nix-cachyos-kernel#110), and a kernel built here is
      # not substitutable anywhere else. Bump this input deliberately and expect
      # one kernel compile per bump.
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    };
}
