# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `nixos`: Desktop NixOS for user `kacper` on `x86_64-linux`.
- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

The shared Home Manager development profile installs oh-my-pi (`omp`) on all
three hosts from nixpkgs, prebuilt by Hydra (`cache.nixos.org`). Do not
override it: any override changes its hash and forces a local build. On Linux
it includes the PipeWire-backed Wayland capture addon.

## Layout

The flake follows the [dendritic pattern](https://discourse.nixos.org/t/the-dendritic-pattern/61271):
[flake-parts](https://flake.parts) with [import-tree](https://github.com/vic/import-tree)
imports every `.nix` file under `modules/` as a flake-parts module. Each file
owns one feature and contributes `flake.modules.nixos.<name>`,
`flake.modules.darwin.<name>` and/or `flake.modules.homeManager.<name>`; a NixOS
feature brings its Home Manager half along through `home-manager.sharedModules`.

- `modules/hosts/`: one file (or directory) per machine, listing the features
  it uses plus host-only settings (hardware, locale, firewall interfaces).
- `modules/system/`: shared system pieces (`nix`, `user`, `theme`, `ssh`, ...).
  `user` wires Home Manager and its shared `base`, `shell` and `dev` modules.
- `modules/desktop/`, `modules/audio/`, `modules/hardware/`, `gaming.nix`,
  `streaming.nix`, `virtualisation.nix`: desktop host features.
- `modules/home/`: Home Manager-only modules.
- `modules/flake/`: flake plumbing; `unfreePackages` is a list each feature
  appends to.
- `pkgs/`: packages nixpkgs lacks, one directory each, exposed as
  `overlays.default` (applied on every host) and `packages.x86_64-linux`, so
  `nix build .#wo-mic` builds one in isolation (`winvm` is also exposed for
  `aarch64-darwin`). Scripts are real `.sh` files.

Adding a file under `modules/` is enough for it to be evaluated; a host still
has to list a feature for it to take effect. Files must be `git add`ed before
the flake can see them. `nix fmt` formats the tree with nixfmt.

## Apply

[nh](https://github.com/nix-community/nh) drives rebuilds and shows a package
diff before switching. Each host has a `rebuild` fish alias for its own config:

```sh
nh os switch -H nixos              # desktop
nh os switch -H wsl                # WSL
nh darwin switch -H macbook-pro-m4 # macOS
```

Bootstrap nix-darwin on macOS:

```sh
nix --extra-experimental-features "nix-command flakes" flake update darwin
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/nix-config#macbook-pro-m4
```

Every host collects garbage weekly (generations older than 14 days) and
deduplicates the store.

## Niri Desktop

The desktop is [niri](https://github.com/YaLTeR/niri) with the
[Noctalia](https://noctalia.dev) shell. Noctalia Greeter logs in to the `niri`
session (`niri-session` → `niri.service` → `graphical-session.target`), and
Home Manager's `noctalia.service` follows that target. X11 clients (Steam,
Proton games) run through xwayland-satellite, which niri starts on demand.

| Key | Action |
| --- | --- |
| `Super + Return` / `Super + B` / `Super + E` | Terminal (raises the open Tern window) / browser / files |
| `Super + Space` | Application launcher |
| `Super + Ctrl + Space` | Control center |
| `Super + Ctrl + V` / `Super + Ctrl + D` | Clipboard / shell settings |
| `Super + O` / `Super + Shift + /` | Overview / hotkey reference |
| `Super + Ctrl + L` | Lock |
| `Super + H/J/K/L` or arrows | Focus column / window or workspace |
| `Super + Shift + H/J/K/L` or arrows | Move column / window or workspace |
| `Super + Ctrl + Shift + H/J/K/L` or arrows | Move window to monitor |
| `Super + 1..9` / `Super + Shift + 1..9` | Switch / move to workspace 1–9 |
| `Super + T` / `Super + F` / `Super + Shift + F` | Floating / fullscreen / maximize column |
| `Super + R` / `Super + -` / `Super + =` | Cycle preset width / shrink / grow column |
| `Super + [` / `Super + ]` / `Super + Shift + W` | Pull window into / push out of column / tabbed column |
| `Alt + Tab` / `Super + Tab` | Window switcher / previous workspace |
| `Super + Shift + S` / `Super + Alt + S` / `Super + Ctrl + S` | Region / window / output screenshot |
| `Super + Shift + E` | Power/session menu |
| `Super + Ctrl + Shift + E` | Quit niri |

The Print Screen variants take the same screenshots; niri copies them to the
clipboard and saves them to `~/Pictures/Screenshots`.

Compositor settings and binds are plain KDL in `modules/desktop/niri/config.kdl`;
`niri.nix` fills in Stylix colours (`@base0D@` etc.) and runs `niri validate`
at build time, so a broken config fails the rebuild instead of the session.
HDMI-A-2 runs 3440×1440 at 99.982 Hz, scale 1, with on-demand VRR for
`steam_app_*` windows (inert over HDMI on Pascal).

Noctalia's defaults are `modules/desktop/noctalia/settings.toml`, validated and
written to `~/.config/noctalia/config.toml`. Changes made in its settings UI go to
`~/.local/state/noctalia/settings.toml`, which overrides the defaults and
survives rebuilds; copy keepers back from `noctalia config export merged`. Stylix's
Noctalia target supplies the palette (Kanagawa Dragon, set in
`modules/system/theme.nix`), theme mode, shell font and popup opacity; Noctalia's
own GTK/Qt/terminal templates are off so they do not overwrite Stylix. The
wallpaper defaults to `~/Documents/wallpapers/31299713726712.jpg`.

### Login screen

Noctalia Greeter runs under greetd in its own wlroots compositor. Its palette is
generated from Stylix in `modules/desktop/noctalia/noctalia.nix`; the shell's
greeter auto-sync copies the wallpaper and monitor layout into
`/var/lib/noctalia-greeter`, through a polkit rule that lets `kacper` run only
that constrained helper without a password. Automatic login is not enabled.

When replacing the greeter, apply at the next boot rather than restarting greetd
under a running desktop:

```sh
nh os boot -H nixos
sudo reboot
```

### Desktop services

`systemctl --user status noctalia` shows the desktop shell. It is also the
notification daemon, polkit agent, idle/lock handler (lock after 15 min, screens
off after 16) and screen recorder: its `noctalia/screen_recorder` plugin drives
gpu-screen-recorder. Portals use GNOME for screen sharing and GTK for file
selection. Sunshine's display-mode helper switches modes with `niri msg output`.

### Recording and peripherals

To use a phone as a microphone, install WO Mic on the phone, start its Wi-Fi
server, and run `wo-mic PHONE_IP` on the desktop with the IP shown in
the app. Select `WO-Mic` as the input in Vesktop, a VM, or another application.
The client and PipeWire source both use WO Mic's native 48 kHz, 16-bit mono
format, avoiding the 16 kHz quality limit and unnecessary resampling.
The launcher loads a WO Mic-only ALSA buffering fix from
`pkgs/wo-mic/wo-mic-buffer.c`: playback waits for three 20 ms packets before
starting. This adds about 40 ms of headroom and prevents the client's
single-packet startup / dropped-underrun-packet cycle from chopping audio.
It does not change other applications' ALSA settings or require running as root.

## Windows VM (winvm)

`winvm` (`pkgs/winvm`, feature `windows-vm` on `nixos` and `macbook-pro-m4`)
runs an unattended Windows 11 Pro VM in QEMU for building and testing Windows
software: ARM64 under HVF on the Mac, x64 under KVM on the desktop. It installs
from Microsoft's ISO (cached in `~/.cache/winvm`), provisions the toolchain, and
syncs host folders two-way into `C:\src\<folder name>` through its own Syncthing
pair (ports 22100/22101/8385, separate from notes-sync). VM state lives in
`~/.local/share/winvm`; `winvm help` lists every command.


`exec`/`gui` run in the guest copy of the current directory. `winvm rdp` opens
Windows App (password on the clipboard); it takes the desktop session off the
console, so `winvm screenshot` shows the sign-in screen until `winvm down; winvm up`.

The toolchain is pinned in `pkgs/winvm/tools.nix` and covers 
VS 2022 Build Tools (MSVC, Windows 11 SDK, signtool), Git,
gh, LLVM, NASM, CMake, Node 22, pnpm 10 (runs each repo's `packageManager`
version), Rust (stable by default, `rust-toolchain.toml` where present), Go 1.26,
.NET 8 and 9 SDKs, Azure CLI with the Artifact Signing client tools, Bun and jq.
On the ARM guest Node, pnpm and Bun are x64 and cargo builds
`x86_64-pc-windows-msvc` by default, because the shipped binaries and native npm
packages are x64.

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
