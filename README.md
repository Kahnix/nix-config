# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `nixos`: Desktop NixOS for user `kacper` on `x86_64-linux`.
- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

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

## Editor

Helix is `EDITOR`/`VISUAL`. Its `config.toml` and `languages.toml` are generated
by Home Manager in `modules/home/dev.nix`, and Stylix supplies the theme. The
same module installs the LSP/formatter toolchain that Helix, Mitos, and Zed share.

Mitos (`ms` / `mitos`) is installed alongside Helix on every host via
`modules/home/mitos.nix`. It inherits Helix's `settings`, `languages`, `themes`,
and `extraPackages` (migrated to Mitos's canonical config schema and validated
at build time), while accepting Mitos-specific overrides under `programs.mitos`.

Zed is installed on graphical hosts as the unwrapped cache.nixos.org build and
fetches its own language servers. Its settings and extensions live in
`modules/home/zed.nix`, so NixOS and macOS render the same Zed setup.

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

## Hyprland Desktop

The desktop is [Hyprland](https://hyprland.org) (Lua config) with a custom
[Quickshell](https://quickshell.org) shell. ReGreet (greetd + cage) logs in to
the `Hyprland (UWSM)` session; UWSM brings up `graphical-session.target`, which
starts the shell and the other user services. X11 clients (Steam, Proton games)
run through Xwayland.

| Key | Action |
| --- | --- |
| `Super + Return` / `Super + B` / `Super + E` | Terminal (Ghostty) / browser / files |
| `Super + Space` | Application launcher (`Tab` switches to clipboard) |
| `Super + Ctrl + V` | Clipboard history (`Shift + Del` removes an entry) |
| `Super + Ctrl + Space` | Control center |
| `Super + Shift + E` / `Super + Ctrl + L` | Session menu / lock |
| `Super + H/J/K/L` or arrows | Focus window |
| `Super + Shift + H/J/K/L` or arrows | Move window |
| `Super + Ctrl + Shift + H/J/K/L` or arrows | Move window to monitor |
| `Super + 1..0` / `Super + Shift + 1..0` | Switch / move to workspace 1–10 |
| `Super + T` / `Super + F` / `Super + Shift + F` | Floating / fullscreen / maximize |
| `Super + R` / `Super + C` | Toggle split / centre window |
| `Super + -` / `Super + =` (`+ Shift`: height) | Shrink / grow window |
| `Super + Shift + W` / `Super + [` / `Super + ]` | Group (tabs) / previous / next tab |
| `Alt + Tab` / `Super + Tab` | Cycle windows / previous workspace |
| `Super + Shift + S` / `Super + Alt + S` / `Super + Ctrl + S` | Region / window / output screenshot |
| `Super + Shift + P` | Monitor off |
| `Super + Ctrl + Shift + E` | Log out |

The Print Screen variants take the same screenshots; `hypr-screenshot` (hyprshot)
copies them to the clipboard and saves them to `~/Pictures/Screenshots`.

Compositor settings are in `modules/desktop/hyprland/hyprland.nix` and binds in
`binds.lua`. Check a change without logging in with
`Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`. HDMI-A-2 runs
3440×1440 at 99.982 Hz, scale 1, with VRR and direct scanout for fullscreen
`steam_app_*` windows (VRR is inert over HDMI on Pascal).

### Shell

`modules/desktop/quickshell/shell` is the whole shell, plain QML:

- **Bar** (`Bar.qml`): floating islands. Left: launcher and workspaces, each
  occupied one showing its windows' icons (red when one is urgent), then the
  focused window. Centre: clock. Right: now playing (spinning cover, cava
  spectrum while playing), CPU/RAM/GPU load (click for Mission Center), and
  status: recording timer, keep-awake, AI quota rings, tray, volume (scroll to
  change, right-click for pavucontrol), notifications and power. Below 2400 px
  wide (Sunshine's 1680×1050 mode) it drops the title, track name and load.
- **Control center** (`ControlCenter.qml`): do not disturb, keep awake
  (idle inhibitor), screen recording, Bluetooth; output and mic volume; now
  playing; per-window AI quotas from `ai-usagebar usage --json`; notification
  history.
- **Launcher** (`Launcher.qml`): apps ranked by match and launch count, and the
  cliphist clipboard history. Apps start through `uwsm app`, so they live in
  their own scopes and survive shell restarts.
- Notifications with toasts (`Notifs.qml`, `Toasts.qml`), volume OSD, session
  menu and the wallpaper.

Colours, fonts and the wallpaper come from Stylix: `quickshell.nix` generates
`Stylix.qml` from the active scheme (Gruvbox Paper, `modules/system/theme.nix`);
`Theme.qml` maps it to semantic colours and holds sizes and glyphs. Panels are
toggled with `qs ipc call shell launcher|clipboard|controlCenter|session|dnd`.
To iterate on the QML without rebuilding, stop the service and run a copy:

```sh
systemctl --user stop quickshell
cp -r ~/.config/quickshell /tmp/qs && chmod -R u+w /tmp/qs
qs -p /tmp/qs   # edit /tmp/qs/*.qml; it reloads on save
```

### Login screen

ReGreet runs under greetd in cage, themed by Stylix with the shell's wallpaper.
It remembers the last user and session. Automatic login is not enabled.

When replacing the greeter, apply at the next boot rather than restarting greetd
under a running desktop:

```sh
nh os boot -H nixos
sudo reboot
```

### Desktop services

`systemctl --user status quickshell` shows the shell; it is also the
notification daemon. Around it: hypridle (lock after 15 min, screens off after
16, lock before sleep), hyprlock, hyprpolkitagent, cliphist and udiskie. Portals
use Hyprland's for screen sharing and GTK for file selection. Screen recording
(control center) uses gpu-screen-recorder with NVENC into `~/Videos/Recordings`.
Sunshine's display-mode helper switches modes with `hyprctl eval`.

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
