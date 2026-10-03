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
- A Kanagawa Dragon palette across DMS, GTK, Ghostty, and btop.
- DankGreeter for login, matching the current DMS appearance and initially selecting **Hyprland + Quickshell (UWSM)**.
- Ghostty, Fish, Starship, and the shared Home Manager development profile.
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

## Hyprland Desktop

After rebuilding the desktop, **Hyprland + Quickshell (UWSM)** is the default
login session. Choose this entry rather than the plain **Hyprland** entry:
UWSM starts Hyprland through `start-hyprland`; the watchdog remains inside the
managed session. DMS follows `graphical-session.target`, not a target named after
the compositor executable. Launcher changes take effect on the next login.

The rice uses [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell),
inspired by its [r/unixporn showcase](https://www.reddit.com/r/unixporn/comments/1mxj44y/hyprland_dankmaterialshell_meets_hyprland/):
a compact floating top bar, workspace pills, Inter/JetBrains Mono typography,
muted blue/teal accents, and opaque application windows. Hyprland uses the native
dwindle layout, modest gaps and animations, and no compositor plugins.

| Key | Hyprland action |
| --- | --- |
| `Super + Return` / `Super + B` / `Super + E` | Terminal / browser / yazi |
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

Compositor settings and bindings live in `home/kacper/hyprland.nix`; the shell
palette, first-launch defaults, and service live in `home/kacper/quickshell.nix`.
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
sudo nixos-rebuild boot --flake ~/nix-config#nixos
sudo reboot
```

### Desktop services

`systemctl --user status dms` shows the desktop shell. Portals use Hyprland
for screen sharing and GTK for file selection. Replay recording follows the
graphical session, and Sunshine's display-mode helper uses Hyprland's Lua API.
Driver, Proton, and game settings are unchanged by the desktop cutover.

The Print Screen variants provide the same screenshot actions.

Docker Manager is also pinned through Home Manager. Its bar widget uses DMS's
visibility-command API to check the configured runtime executable with
`command -v`, initially and every 30 seconds. It is hidden when the executable
is absent; daemon health and container count do not control visibility.
Change its pinned source and `docker-manager-visibility.patch` through Nix,
not `dms plugins update dockerManager`.

The built-in focused-window widget is retained. DMS 1.6.2 has no application-name-only
mode and no launcher-wide hide-icons setting; neither is patched into DMS.

### Recording and peripherals

The DMS Screen Recorder plugin is pinned and patched by Home Manager in
`home/kacper/quickshell.nix`. Its **Video encoder** setting defaults to Vulkan
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
then update `settings.monitor` in `home/kacper/hyprland.nix` for a fixed layout.

To use a phone as a microphone, install WO Mic on the phone, start its Wi-Fi
server, and run `wo-mic PHONE_IP` on the desktop with the IP shown in
the app. Select `WO-Mic` as the input in Vesktop, a VM, or another application.
The client and PipeWire source both use WO Mic's native 48 kHz, 16-bit mono
format, avoiding the 16 kHz quality limit and unnecessary resampling.
The launcher loads a WO Mic-only ALSA buffering fix from
`hosts/nixos/wo-mic-buffer.c`: playback waits for three 20 ms packets before
starting. This adds about 40 ms of headroom and prevents the client's
single-packet startup / dropped-underrun-packet cycle from chopping audio.
It does not change other applications' ALSA settings or require running as root.

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
