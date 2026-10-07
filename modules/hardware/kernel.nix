{ inputs, ... }:
{
  flake.modules.nixos.kernel =
    { pkgs, ... }:
    {
      # Pinned is cache-friendly: it tracks kernels the CachyOS cache has built.
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

      nix.settings = {
        substituters = [ "https://attic.xuyh0120.win/lantian" ];
        trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
      };
    };
}
