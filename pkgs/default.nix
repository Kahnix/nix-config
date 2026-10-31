# Packages that nixpkgs does not ship, or ships without a fix this config needs.
# Exposed as `overlays.default` (applied on every host) and as
# `packages.x86_64-linux`, so each one builds on its own: `nix build .#wo-mic`.
{ pkgs }:
let
  javaAlsaDefault = import ./java-alsa-default.nix { inherit (pkgs) makeWrapper symlinkJoin; };
in
{
  # Bloodborne Seamless Co-op (github.com/Classmg22/BBSC) on Linux: the shadPS4
  # fork without its built-in BBSC, the bbsc mod ported to a Linux .so, and the
  # Qt launcher fork (accounts, mods).
  bbsc-emulator = pkgs.callPackage ./bbsc/emulator.nix { };
  bbsc-launcher = pkgs.callPackage ./bbsc/launcher.nix { };
  bbsc-mod = pkgs.callPackage ./bbsc/mod.nix { };
  bolt-launcher-alsa = javaAlsaDefault pkgs.bolt-launcher "bolt-launcher";
  dzgui = pkgs.callPackage ./dzgui/package.nix { };
  gamma-direct = pkgs.callPackage ./gamma-direct/package.nix { };
  gparted-with-display = pkgs.callPackage ./gparted-with-display/package.nix { };
  niri-focus-or-spawn = pkgs.callPackage ./niri-focus-or-spawn/package.nix { };
  proton-cachyos-bin = pkgs.callPackage ./proton-cachyos-bin/package.nix { };
  # Preloaded into Steam's 32-bit client, so it is built for i686.
  steam-voicechat-fix = pkgs.pkgsi686Linux.callPackage ./steam-voicechat-fix/package.nix { };
  stream-display-mode = pkgs.callPackage ./stream-display-mode/package.nix { };
  # Windows 11 VM (QEMU, HVF on Apple Silicon / KVM on Linux) for building and testing the Windows app.
  winvm = pkgs.callPackage ./winvm/package.nix { };
  wo-mic = pkgs.callPackage ./wo-mic/package.nix { };
}
