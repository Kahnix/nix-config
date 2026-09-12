{ ... }:

{
  nixpkgs.config.allowUnfreePackages = [
    "google-chrome"
    "nvidia-settings"
    "nvidia-x11"
    "obsidian"
    "proton-cachyos-bin"
    "proton-ge-bin"
    "steam"
    "steam-original"
    "steam-run"
    "discord"
    "discord-unwrapped"
    "steam-unwrapped"
  ];
}
