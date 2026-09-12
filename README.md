# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `nixos`: Desktop NixOS for user `kacper` on `x86_64-linux`.
- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

## Desktop

The `nixos` host uses:

- Niri's scrollable tiling layout with Xwayland Satellite for legacy applications.
- Noctalia for the bar, launcher, control center, notifications, clipboard, wallpaper, and lock screen.
- A Kanagawa palette across Noctalia, GTK, Ghostty, and btop.
- A Kanagawa-themed Noctalia greeter that starts the selected greetd session.
- Ghostty, Fish, Starship, and the shared Home Manager development profile.
- Zen Browser, Proton Pass, Proton Mail, Proton VPN, Telegram, Obsidian, and Vesktop for Discord.
- Niri's native screenshots, copied and saved to `~/Pictures/Screenshots`.
- WO Mic at its native 48 kHz/16-bit mono format for using a phone as a microphone.
- NVIDIA's proprietary 580 driver and a CachyOS kernel.
- Steam, Gamescope, GameMode, Proton-GE, Heroic, Lutris, MangoHud, and Wine.
- libvirt/KVM, virt-manager, swtpm, Quickemu, SPICE, and VirtioFS for Windows VM work.

Suspend, hibernation, hybrid sleep, and suspend-then-hibernate are disabled at
the systemd sleep and logind layers. The bar and control-center shortcuts
intentionally have no suspend action.

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

## Niri Keys

| Key | Action |
| --- | --- |
| `Super + Return` | Terminal |
| `Super + Space` | Application launcher |
| `Super + Ctrl + Space` | Control center |
| `Super + Ctrl + V` | Clipboard history |
| `Super + Ctrl + D` | Noctalia settings |
| `Alt + Tab` | Window switcher |
| `Super + O` | Niri overview |
| `Super + B` / `Super + E` | Browser / files |
| `Super + Shift + G` | Steam |
| `Super + Shift + V` | virt-manager |
| `Super + Ctrl + L` | Lock |
| `Super + H/J/K/L` | Focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move a column/window |
| `Super + 1..9` | Switch workspace |
| `Super + Shift + 1..9` | Move window to workspace |
| `Super + Shift + S` | Interactive screenshot |
| `Super + Alt + S` | Window screenshot |
| `Super + Ctrl + S` | Screen screenshot |
| `Super + Shift + /` | Hotkey reference |

The Print Screen variants provide the same screenshot actions. Niri saves
captures to `~/Pictures/Screenshots` and also puts them on the clipboard.

Outputs use their preferred modes and automatic positions by default. Run
`niri msg outputs` to get connector names, then add explicit `output` blocks to
`home/kacper/niri.kdl` when a fixed multi-monitor layout is needed.

Noctalia's declarative defaults live in `home/kacper/linux-desktop.nix`. Changes
made in its settings UI are saved to
`~/.local/state/noctalia/settings.toml` and override those defaults.

To use a phone as a microphone, install WO Mic on the phone, start its Wi-Fi
server, and run `wo-mic PHONE_IP` on the desktop with the IP shown in
the app. Select `WO-Mic` as the input in Vesktop, a VM, or another application.
The client and PipeWire source both use WO Mic's native 48 kHz, 16-bit mono
format, avoiding the 16 kHz quality limit and unnecessary resampling.

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
