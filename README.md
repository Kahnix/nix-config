# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `nixos`: Desktop NixOS for user `kacper` on `x86_64-linux`.
- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

## Desktop

The `nixos` host uses:

- Hyprland with a native Lua configuration.
- A custom Quickshell bar, launcher, control center, notifications, and greetd greeter.
- Cage as the small Wayland compositor around the login screen.
- Ghostty, Fish, Starship, and the shared Home Manager development profile.
- Zen Browser, Proton Pass, Proton Mail, Proton VPN, Telegram, Obsidian, and Vesktop for Discord.
- Satty annotations on top of Hyprshot, with finished captures copied and saved to `~/Pictures/Screenshots`.
- A `phone-mic` command that exposes an Android phone through PipeWire using scrcpy.
- The Neovim configuration pinned from `Kahnix/nvim-config`.
- NVIDIA's proprietary 580 driver and a CachyOS kernel.
- Steam, Gamescope, GameMode, Proton-GE, Heroic, Lutris, MangoHud, and Wine.
- libvirt/KVM, virt-manager, swtpm, Quickemu, SPICE, and VirtioFS for Windows VM work.

Suspend, hibernation, hybrid sleep, and suspend-then-hibernate are disabled at
the systemd sleep and logind layers. The desktop UI intentionally has no
suspend action.

The generated visual reference is in `assets/design/quickshell-concept.png`.
The active wallpaper is `assets/wallpapers/blue-hour.png`.

## Apply

Rebuild desktop NixOS:

```sh
sudo nixos-rebuild switch --flake ~/nix-config#nixos
```

Rebuild WSL:

```sh
sudo nixos-rebuild switch --flake ~/nix-config#wsl
```

Bootstrap nix-darwin on macOS:

```sh
nix --extra-experimental-features "nix-command flakes" flake update darwin
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/nix-config#macbook-pro-m4
```

Rebuild macOS after bootstrap:

```sh
sudo darwin-rebuild switch --flake ~/nix-config#macbook-pro-m4
```

## Hyprland Keys

| Key | Action |
| --- | --- |
| `Super + Return` | Terminal |
| `Super + Space` | Application launcher |
| `Super + Ctrl + Space` | Control center |
| `Super + B` / `Super + E` | Browser / files |
| `Super + Shift + G` | Steam |
| `Super + Shift + V` | virt-manager |
| `Super + Ctrl + V` | Clipboard history |
| `Super + K` | Lock |
| `Super + 1..9` | Switch workspace |
| `Super + Shift + 1..9` | Move window to workspace |
| `Print` / `Shift + Print` | Region / window screenshot |

Finish a screenshot annotation with `Enter` to copy it, save it, and close
Satty. Use `Ctrl + Print` for an entire output.

To use an Android 11 or newer phone as a microphone, enable USB debugging,
connect it, and run:

```sh
phone-mic
```

Select `Phone Microphone` as the input in Vesktop, a VM, or another app. The
temporary PipeWire source is removed when the command exits.

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
