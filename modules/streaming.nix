{
  # Sunshine game streaming to Moonlight, reachable over Tailscale only.
  flake.modules.nixos.streaming =
    { lib, pkgs, ... }:
    let
      displayMode = mode: "${lib.getExe pkgs.stream-display-mode} ${mode}";

      # Moonlight app list. Sunshine reads it from its appdata path
      # (~/.config/sunshine/apps.json) unless the config pins file_apps, and that
      # default path is what a launcher-started `sunshine` (not the systemd unit)
      # also loads. Feed the same definition to both.
      applications = {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = [
          {
            name = "Desktop";
            "image-path" = "desktop.png";
            "prep-cmd" = [
              {
                do = displayMode "1680x1050@59.954";
                # Restore the desktop's configured ultrawide refresh rate.
                undo = displayMode "3440x1440@99.982";
              }
            ];
          }
          {
            name = "Ultrawide Desktop";
            "image-path" = "desktop.png";
          }
          {
            name = "Steam Big Picture";
            detached = [ "setsid steam steam://open/bigpicture" ];
            "prep-cmd" = [
              {
                do = "";
                undo = "setsid steam steam://close/bigpicture";
              }
            ];
            "image-path" = "steam.png";
          }
        ];
      };
    in
    {
      services.sunshine = {
        enable = true;
        autoStart = true;
        openFirewall = false;
        inherit applications;
      };

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [
          47984
          47989
          47990
          48010
        ];
        allowedUDPPorts = [
          47998
          47999
          48000
          48002
          48010
        ];
      };

      home-manager.sharedModules = [
        {
          xdg.configFile."sunshine/apps.json".source =
            (pkgs.formats.json { }).generate "sunshine-apps.json"
              applications;
        }
      ];
    };
}
