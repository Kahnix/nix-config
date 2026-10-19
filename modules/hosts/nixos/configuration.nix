{ config, inputs, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  # Desktop: Ryzen 3700X, NVIDIA (580 legacy driver), 3440x1440 ultrawide.
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = with modules; [
      host-nixos

      base
      nix
      user
      theme
      ssh
      tailscale
      nix-ld

      kernel
      nvidia
      pipewire
      wo-mic

      hyprland
      dms
      desktop-apps
      tern

      gaming
      streaming
      virtualisation
      notes-sync
    ];
  };

  flake.modules.nixos.host-nixos =
    { config, pkgs, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking = {
        hostName = "nixos";
        networkmanager.enable = true;
        # 8376/udp: `tern remote serve` (QUIC) on the LAN as well as Tailscale.
        firewall.interfaces.enp7s0.allowedUDPPorts = [
          49152
          8376
        ];
      };

      time.timeZone = "Europe/Warsaw";
      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "pl_PL.UTF-8";
          LC_IDENTIFICATION = "pl_PL.UTF-8";
          LC_MEASUREMENT = "pl_PL.UTF-8";
          LC_MONETARY = "pl_PL.UTF-8";
          LC_NAME = "pl_PL.UTF-8";
          LC_NUMERIC = "pl_PL.UTF-8";
          LC_PAPER = "pl_PL.UTF-8";
          LC_TELEPHONE = "pl_PL.UTF-8";
          LC_TIME = "pl_PL.UTF-8";
        };
      };
      console.keyMap = "us";
      services.xserver.xkb.layout = "us";

      users.users.${config.my.user} = {
        description = "Kacper";
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "video"
        ];
      };

      services.logind.settings.Login = {
        HandleHibernateKey = "ignore";
        HandleLidSwitch = "ignore";
        HandlePowerKey = "ignore";
        IdleAction = "ignore";
      };

      systemd.sleep.settings.Sleep = {
        AllowSuspend = true;
        AllowHibernation = true;
        AllowHybridSleep = true;
        AllowSuspendThenHibernate = true;
      };

      # 16 GiB RAM: give the kernel a compressed eviction target first. lz4
      # decompresses ~3x faster than the default zstd, which is the trade that
      # matters when swapped pages are faulted back in mid-frame. zram alone filled
      # up and OOM-killed AION 2, so a disk swapfile (hardware.nix) backs it as
      # lower-priority overflow. Forza Horizon 6 alone holds ~9 GiB resident, so let
      # zram cover all of RAM (~3:1 with lz4) before anything reaches the NVMe file.
      zramSwap = {
        enable = true;
        algorithm = "lz4";
        memoryPercent = 100;
      };

      # Swap is in-memory zram first: prefer swapping cold anon pages over dropping
      # the page cache that games stream assets from (>100 is valid with zram), and
      # fault single pages back in, since readahead only pays off on disks.
      boot.kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.page-cluster" = 0;
      };

      # A game that fills RAM can starve zram of the memory it compresses into,
      # and the kernel then livelocks in reclaim (STALKER GAMMA froze the whole
      # desktop this way, past the kernel OOM killer). systemd-oomd watches memory
      # pressure in user sessions and kills the worst cgroup (usually the game's
      # Steam unit) after 10 s above the limit, instead of the 30 s default.
      systemd.oomd = {
        enableUserSlices = true;
        settings.OOM.DefaultMemoryPressureDurationSec = "10s";
      };

      environment.systemPackages = [ pkgs.pciutils ];

      home-manager.users.${config.my.user}.programs.fish.shellAliases.rebuild = "nh os switch -H nixos";

      system.stateVersion = "26.05";
    };
}
