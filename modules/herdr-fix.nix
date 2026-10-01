{ ... }:

{
  # herdr's vendored libghostty-vt bundles Zig's compiler-rt, whose zero-address
  # unwind records end up in the final executable; ld.bfd (binutils 2.46 with
  # GCC 16) rejects those as overlapping FDEs, so herdr 0.9.1 fails to link on
  # Linux and nixpkgs ships no cached build for it (Hydra build 347137433).
  # Rust already provides the compiler builtins, so the bundle is redundant.
  # Mirrors the pending upstream fix; remove once
  # https://github.com/NixOS/nixpkgs/pull/568618 is merged and cached.
  nixpkgs.overlays = [
    (_final: prev: {
      herdr = prev.herdr.overrideAttrs (
        old:
        prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace vendor/libghostty-vt/src/build/GhosttyLibVt.zig \
              --replace-fail 'lib.bundle_compiler_rt = true;' 'lib.bundle_compiler_rt = false;'
          '';
        }
      );
    })
  ];
}
