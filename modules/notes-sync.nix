{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;

  # Syncthing listen port; peers dial each other on it over Tailscale.
  port = 22000;

  # Device IDs come from each host's Syncthing key (`syncthing device-id`).
  # Addresses are the hosts' Tailscale IPs, so traffic never leaves the tailnet.
  devices = {
    macbook-pro-m4 = {
      id = "WAZQOSB-H2YG66C-XCYCJWX-463VQBX-VQAQV5U-KQXWYSZ-QMJMSUI-Q2CLFAA";
      ip = "100.93.135.72";
    };
    nixos = {
      id = "O4RXG2K-OIIW7WV-QAJN7LU-OL34GVJ-AND23KH-J3FNBX3-LUYLOSW-CM5AHA4";
      ip = "100.121.38.12";
    };
  };
in
{
  # Obsidian vault sync. The Mac keeps the vault in iCloud Drive (shared with
  # Windows); Syncthing mirrors that folder to NixOS, where iCloud is unavailable.
  flake.modules.homeManager.notes-sync =
    { lib, pkgs, ... }:
    {
      services.syncthing = {
        enable = true;
        # Devices and folders are fully owned here; GUI edits revert on restart.
        overrideDevices = true;
        overrideFolders = true;

        settings = {
          options = {
            # Peers are reached directly over Tailscale.
            globalAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
            urAccepted = -1;
          };

          devices = lib.mapAttrs (_: device: {
            inherit (device) id;
            addresses = [
              "tcp://${device.ip}:${toString port}"
              "quic://${device.ip}:${toString port}"
            ];
          }) devices;

          folders.notes = {
            id = "obsidian-notes";
            label = "Notes";
            path =
              if pkgs.stdenv.hostPlatform.isDarwin then
                "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes"
              else
                "~/Notes";
            devices = lib.attrNames devices;
            ignorePatterns = [
              # Per-device window layout, rewritten by every Obsidian client.
              ".obsidian/workspace*.json"
              "(?d).DS_Store"
            ];
          };
        };
      };
    };

  flake.modules.darwin.notes-sync = {
    home-manager.sharedModules = [ homeModules.notes-sync ];
  };

  flake.modules.nixos.notes-sync = {
    home-manager.sharedModules = [ homeModules.notes-sync ];

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [ port ];
      allowedUDPPorts = [ port ];
    };
  };
}
