# Packages that nixpkgs does not ship, or ships without a fix this config needs.
# Exposed as `overlays.default` (applied on every host) and as
# `packages.x86_64-linux`, so each one builds on its own: `nix build .#wo-mic`.
{ pkgs }:
{
  bolt-launcher-alsa = pkgs.callPackage ./bolt-launcher-alsa/package.nix { };
  dms-plugin-docker-manager = pkgs.callPackage ./dms-plugins/docker-manager.nix { };
  dms-plugin-screen-recorder = pkgs.callPackage ./dms-plugins/screen-recorder.nix { };
  dzgui = pkgs.callPackage ./dzgui/package.nix { };
  gparted-with-display = pkgs.callPackage ./gparted-with-display/package.nix { };
  gsr-gamemode-hook = pkgs.callPackage ./gsr-gamemode-hook/package.nix { };
  gsr-replay = pkgs.callPackage ./gsr-replay/package.nix { };
  hypr-screenshot = pkgs.callPackage ./hypr-screenshot/package.nix { };
  proton-cachyos-bin = pkgs.callPackage ./proton-cachyos-bin/package.nix { };
  # Preloaded into Steam's 32-bit client, so it is built for i686.
  steam-voicechat-fix = pkgs.pkgsi686Linux.callPackage ./steam-voicechat-fix/package.nix { };
  stream-display-mode = pkgs.callPackage ./stream-display-mode/package.nix { };
  wo-mic = pkgs.callPackage ./wo-mic/package.nix { };
}
