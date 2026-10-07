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
      replay-buffer
      tern

      gaming
      streaming
      virtualisation
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
      # lower-priority overflow.
      zramSwap = {
        enable = true;
        algorithm = "lz4";
      };

      environment.systemPackages = [ pkgs.pciutils ];

      home-manager.users.${config.my.user}.programs.fish.shellAliases.rebuild = "nh os switch -H nixos";

      system.stateVersion = "26.05";
    };
}
