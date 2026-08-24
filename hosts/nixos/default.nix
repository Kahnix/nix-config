{
  config,
  inputs,
  pkgs,
  system,
  username,
  homeDirectory,
  isNixOS,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gaming.nix
    ../../modules/virtualisation.nix
  ];

  nixpkgs = {
    hostPlatform = system;
    overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  };

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    blacklistedKernelModules = [ "nouveau" ];
    kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
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

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Kacper";
    home = homeDirectory;
    shell = pkgs.fish;
    extraGroups = [
      "audio"
      "gamemode"
      "input"
      "kvm"
      "libvirtd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  programs = {
    dconf.enable = true;
    fish.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    nix-ld.enable = true;
  };

  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = builtins.concatStringsSep " " [
          "${pkgs.coreutils}/bin/env"
          "KACPER_WALLPAPER=${../../assets/wallpapers/blue-hour.png}"
          "KACPER_SESSION=${config.programs.hyprland.package}/bin/Hyprland"
          "${pkgs.cage}/bin/cage -s --"
          "${pkgs.quickshell}/bin/qs -p ${../../home/kacper/quickshell-greeter}"
        ];
      };
    };

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack.enable = true;
      pulse.enable = true;
    };

    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    tailscale.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;

    logind.settings.Login = {
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
      HandlePowerKey = "ignore";
      HandleSuspendKey = "ignore";
      IdleAction = "ignore";
    };
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.nvidia-vaapi-driver ];
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      powerManagement.enable = true;
    };
  };

  environment = {
    sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      LIBVA_DRIVER_NAME = "nvidia";
      NIXOS_OZONE_WL = "1";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    systemPackages = with pkgs; [
      curl
      git
      pciutils
      tailscale
      tuigreet
      wget
    ];
  };

  fonts.packages = with pkgs; [
    departure-mono
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    extraSpecialArgs = {
      inherit
        inputs
        username
        homeDirectory
        isNixOS
        ;
      isDarwin = false;
      isWSL = false;
    };
    users.${username} = import ../../home/kacper;
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    stateVersion = "26.05";
  };
}
