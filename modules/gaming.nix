{ inputs, ... }:
{
  unfreePackages = [
    # Official Jagex Launcher; RuneLite on a Jagex Account without Bolt.
    "jagex-launcher"
    # Lossless Scaling frame generation layer (CC BY-NC-ND).
    "lsfg-vk"
    "lsfg-vk-ui"
    "proton-cachyos-bin"
    "proton-ge-bin"
    "steam"
    "steam-original"
    "steam-run"
    "steam-unwrapped"
    # gamma-launcher extracts GAMMA's .rar mod archives with it.
    "unrar"
  ];

  flake.modules.nixos.gaming =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.jagex-launcher.overlays.default ];

      # ntsync: kernel-side NT sync primitives. Proton 11's wineserver uses
      # /dev/ntsync automatically when it exists, replacing esync/fsync.
      boot.kernelModules = [ "ntsync" ];

      users.users.${config.my.user}.extraGroups = [ "gamemode" ];

      programs.steam = {
        enable = true;

        # The 32-bit client's SILK/Speex voice decoder clobbers EBX (the i386 GOT
        # base) before calling memmove through its PLT stub, so the indirect jump
        # reads a decoded-voice buffer and segfaults the client the moment a
        # non-Steam player speaks in CS 1.6 (halflife#3895 / #3898, unfixed
        # upstream since 2025). The preload (pkgs/steam-voicechat-fix) rewrites
        # that stub to a direct jump -- in the client process only, never in a
        # game process. Drop the override if Valve ever fixes it, or to trade the
        # crash risk for ABI-patch risk.
        package = pkgs.steam.override {
          extraEnv.LD_PRELOAD = "${pkgs.steam-voicechat-fix}/lib/libsteam_voicechat_fix.so";
        };

        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-cachyos-bin
        ];
        # Winetricks verbs into a Steam game's Proton prefix (STALKER GAMMA's MO2
        # shortcut needs d3dx/d3dcompiler/vcrun).
        protontricks.enable = true;
        # Lossless Scaling frame generation for Vulkan/DXVK games. The layer loads
        # the shaders from the Steam copy of Lossless Scaling (its "lsfg-vk" beta
        # branch) and turns on per game from ~/.config/lsfg-vk/conf.toml, which
        # lsfg-vk-ui edits. It has to be in Steam's own FHS env: that env builds
        # its own /run/opengl-driver, so hardware.graphics layers never reach
        # the game's runtime container.
        extraPackages = [ pkgs.lsfg-vk ];
      };

      programs.gamemode.enable = true;
      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      # STALKER GAMMA co-op (xrRazom) hosted by IP instead of Steam ID: its
      # GameNetworkingSockets listener (xrr_host_lan_port, UDP 27015), reachable
      # by friends over Tailscale only.
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 27015 ];

      # GPU overclock/fan control. `settings` is deliberately left empty: the NixOS
      # module then leaves /etc/lact/config.yaml owned by lactd, so offsets can be
      # tuned live from the LACT GUI or its socket (wheel members are admins).
      # Populating `settings` would make the file a read-only store symlink.
      services.lact.enable = true;
      # The "gaming" profile (OC offsets) switches on with gamemode. LACT talks to
      # gamemoded via `sudo -u <user> busctl --user`, and NixOS's setuid sudo lives
      # in /run/wrappers/bin, which the unit's default PATH lacks.
      systemd.services.lactd.path = [ "/run/wrappers" ];

      # sched_ext scheduler (CachyOS kernel has CONFIG_SCHED_CLASS_EXT). LAVD
      # boosts latency-critical threads (a game's render/game threads) over
      # background throughput work. `systemctl stop scx` falls back to the
      # kernel's built-in scheduler instantly.
      services.scx = {
        enable = true;
        scheduler = "scx_lavd";
      };

      environment.systemPackages = with pkgs; [
        bolt-launcher-alsa
        dzgui
        jagex-launcher
        # STALKER GAMMA: installs/updates Anomaly + the GAMMA modpack natively
        # (/mnt/storage/Games/STALKER); MO2 then runs as a non-Steam Proton game.
        gamma-launcher
        # Launches GAMMA without MO2's slow virtual file system (see the package).
        gamma-direct
        lsfg-vk-ui
        lutris
        mangohud
        prismlauncher
        protonup-qt
        wineWow64Packages.staging
        winetricks
      ];
    };
}
