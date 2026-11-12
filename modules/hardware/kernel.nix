{ inputs, ... }:
{
  flake.modules.nixos.kernel =
    { pkgs, ... }:
    {
      boot.kernelPackages =
        (pkgs.linuxPackagesFor
          inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.linux_cachyos-eevdf
        ).extend
          (_final: _prev: { stdenv = pkgs.stdenv; });
    };
}
