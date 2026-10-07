# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `nixos`: Desktop NixOS for user `kacper` on `x86_64-linux`.
- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

The shared Home Manager development profile installs oh-my-pi (`omp`) on all
three hosts. The NixOS desktop enables its PipeWire-backed Wayland capture
addon; WSL and macOS use the default build.

## Desktop

The `nixos` host uses:

- Hyprland with DankMaterialShell, built on Quickshell, as the default UWSM-managed session.
- DMS for the bar, launcher, control center, notifications, clipboard, wallpaper, and lock screen.
- A Kanagawa Dragon palette across DMS, GTK, Ghostty (macOS), and btop.
- DankGreeter for login, matching the current DMS appearance and initially selecting **Hyprland + Quickshell (UWSM)**.
- Tern (NixOS) and Ghostty (macOS) terminals, Fish, Starship, and the shared Home Manager development profile.
- Zen Browser, Proton Pass, Proton Mail, Proton VPN, Telegram, Obsidian, and Vesktop for Discord.
- Hyprshot screenshots, copied and saved to `~/Pictures/Screenshots`.
- GPU Screen Recorder for a ShadowPlay-style 60 s replay buffer, plus
  `wf-recorder` for one-shot clips.
- WO Mic at its native 48 kHz/16-bit mono format for using a phone as a microphone.
- NVIDIA's proprietary 580 driver and a CachyOS kernel.
- Steam, DZGUI, Gamescope, GameMode, Proton-GE, Heroic, Lutris, MangoHud, and Wine.
- libvirt/KVM, virt-manager, swtpm, Quickemu, SPICE, and VirtioFS for Windows VM work.

Hyprland integrates Xwayland for X11 applications, including Steam and legacy
games. Xwayland Satellite is not needed. Niri and Noctalia have been removed;
DankGreeter provides the login screen.

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
  `nix build .#wo-mic` builds one in isolation. Scripts are real `.sh` files.

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

## Hyprland Desktop

After rebuilding the desktop, **Hyprland + Quickshell (UWSM)** is the default
login session. UWSM starts it from Hyprland's own `hyprland.desktop` entry, so
the `start-hyprland` watchdog launcher is used and `XDG_CURRENT_DESKTOP` is
plain `Hyprland`. DMS follows `graphical-session.target`. Launcher changes take
effect on the next login.

The rice uses [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell),
inspired by its [r/unixporn showcase](https://www.reddit.com/r/unixporn/comments/1mxj44y/hyprland_dankmaterialshell_meets_hyprland/):
a compact floating top bar, workspace pills, Inter/JetBrains Mono typography,
muted blue/teal accents, and opaque application windows. Hyprland uses the native
dwindle layout, modest gaps and animations, and no compositor plugins.

| Key | Hyprland action |
| --- | --- |
| `Super + Return` / `Super + B` / `Super + E` | Terminal / browser / files |
| `Super + Space` | Spotlight application launcher |
| `Super + Ctrl + Space` | Control center |
| `Super + Ctrl + V` / `Super + Ctrl + D` | Clipboard / shell settings |
| `Super + O` / `Super + Shift + /` | Window overview / hotkey reference |
| `Super + Ctrl + L` | Lock |
| `Super + H/J/K/L` or arrows | Focus a window |
| `Super + Shift + H/J/K/L` or arrows | Move a window |
| `Super + 1..9,0` / `Super + Shift + 1..9,0` | Switch / move to workspace 1–10 |
| `Super + left/right mouse drag` | Move / resize a window |
| `Super + T` / `Super + F` / `Super + Shift + F` | Floating / fullscreen / maximize |
| `Super + R` / `Super + Shift + W` | Change split direction / toggle tabbed group |
| `Alt + Tab` / `Super + Tab` | Next window / previous workspace |
| `Super + Shift + S` / `Super + Alt + S` / `Super + Ctrl + S` | Region / window / output screenshot |
| `Super + Alt + R` / `Super + Alt + Shift + R` | Save / toggle replay buffer |
| `Super + Shift + E` | Power/session menu |
| `Super + Ctrl + Shift + E` | Log out through UWSM directly |

Compositor settings live in `modules/desktop/hyprland/hyprland.nix`; key
bindings are plain Lua in `modules/desktop/hyprland/binds.lua`, with a
`.luarc.json` beside it that points lua-language-server at Hyprland's API stubs.
The shell palette, first-launch defaults, plugins and service live in
`modules/desktop/dms.nix`.
The existing HDMI-A-2 mode is retained at 3440×1440, 99.982 Hz, scale 1.

DMS settings are seeded only when absent in
`~/.config/DankMaterialShell/settings.json`; wallpaper/session state lives in
`~/.local/state/DankMaterialShell/session.json`. UI changes survive rebuilds.
First launch prefers `~/Documents/wallpapers/31299713726712.jpg`, with a packaged
dark gradient if it is absent. The Kanagawa theme is a managed file at
`~/.config/DankMaterialShell/kanagawa-dragon.json`. DMS application-theme
generation is disabled so it does not overwrite Stylix.

### Login screen

DankGreeter runs under greetd in a separate Hyprland instance. On greetd startup,
the NixOS module copies the user's DMS settings, wallpaper, and custom theme into
`/var/lib/dms-greeter`, so the login UI does not need access to the user's home.
The initial user and UWSM session are seeded once; later selections are remembered.
Automatic login is not enabled.

When replacing the greeter, apply at the next boot rather than restarting greetd
under a running desktop:

```sh
nh os boot -H nixos
sudo reboot
```

### Desktop services

`systemctl --user status dms` shows the desktop shell. Portals use Hyprland
for screen sharing and GTK for file selection. Replay recording follows the
graphical session, and Sunshine's display-mode helper uses Hyprland's Lua API.
Driver, Proton, and game settings are unchanged by the desktop cutover.

The Print Screen variants provide the same screenshot actions.

Docker Manager is pinned in `pkgs/dms-plugins/` and installed system-wide by the
nixpkgs `programs.dms-shell` module into `/etc/xdg/quickshell/dms-plugins`. Its bar widget uses DMS's
visibility-command API to check the configured runtime executable with
`command -v`, initially and every 30 seconds. It is hidden when the executable
is absent; daemon health and container count do not control visibility.
Change its pinned source and `docker-manager-visibility.patch` through Nix,
not `dms plugins update dockerManager`.

The built-in focused-window widget is retained. DMS 1.6.2 has no application-name-only
mode and no launcher-wide hide-icons setting; neither is patched into DMS.

### Recording and peripherals

The DMS Screen Recorder plugin is pinned and patched in
`pkgs/dms-plugins/`. Its **Video encoder** setting defaults to Vulkan
H.264 for NVIDIA 580; native-GPU and CPU H.264 remain selectable. The plugin's
portal check requires `gdbus` from GLib and `grep`, both installed in the user
profile. The Hyprland ScreenCast portal stays enabled; capture does not fall
back to All screens. Update the pinned revision and codec patch through Nix,
not `dms plugins update screenRecorder`. The previous writable Screen Recorder
and Docker Manager checkouts are retained outside plugin discovery under
`~/.local/state/nix-config/dms-plugin-backups/`.

Replay capture runs as the user service `gsr-replay.service`, started with the
graphical session and writing to `~/Videos/Replays`. NVENC is unusable with
NVIDIA 580 here: GPU Screen Recorder reports NVENC API 13.0 while the FFmpeg it
links against requires 13.1, so the service encodes with Vulkan Video
(`-k h264_vulkan`); `-k h264_software` is the fallback. `gsr-replay save 30` and
`gsr-replay toggle` drive the same code paths as the binds. For a one-shot clip
with the hardware encoder, bypass the buffer:
`wf-recorder -c h264_nvenc -f ~/Videos/clip.mp4`, stopped with
`pkill -INT wf-recorder`.

Outputs use their preferred modes and automatic positions by default, with an
explicit mode for HDMI-A-2. Run `hyprctl monitors all` to get connector names,
then update `settings.monitor` in `modules/desktop/hyprland/hyprland.nix` for a fixed layout.

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

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
