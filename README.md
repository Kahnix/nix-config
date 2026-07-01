# nix-config

Personal NixOS, WSL, macOS, Home Manager, devenv, and direnv configuration.

## Hosts

- `wsl`: NixOS-WSL for user `kacper` on `x86_64-linux`.
- `macbook-pro-m4`: nix-darwin for user `kacperdaniel` on `aarch64-darwin`.

## Apply

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

## Development Shell

Home Manager installs `devenv` and enables `direnv` with `nix-direnv`.
Allow this repository's development shell once:

```sh
direnv allow
```
