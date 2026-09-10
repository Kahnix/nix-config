{ ... }:

{
  nixpkgs.config.allowUnfreePackages = [
    "google-chrome"
    "nvidia-settings"
    "nvidia-x11"
    "obsidian"
    "proton-ge-bin"
    "steam"
    "steam-original"
    "steam-run"
    "steam-unwrapped"
  ];
}
