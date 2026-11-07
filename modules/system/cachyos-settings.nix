{ inputs, ... }:
{
  flake.modules.nixos.cachyos-settings = {
    imports = [ inputs.cachyos-settings-nix.nixosModules.default ];

    # Areas left off, and why:
    # - sysctl: its zram udev rule sets vm.swappiness=150 when zram0 starts, overriding configuration.nix's 180.
    # - zram: configuration.nix's zramSwap (lz4) is deliberate; the area would replace it.
    # - oomd: configuration.nix already sets systemd.oomd with a 10s window.
    # - ntsync: already loaded in gaming.nix.
    # - nvidia: skips zeroing system memory handed to the GPU driver.
    # - serviceManager: 10s stop timeout can kill Steam or a game mid-save at shutdown.
    # - journal: 50M cap drops the crash logs needed for debugging.
    cachyos.settings = {
      enable = true;
      ioSchedulers.enable = true;
      audio.enable = true;
      storage.enable = true;
      thp.enable = true;
      coredump.enable = true;
      watchdogBlacklist.enable = true;
    };
  };
}
