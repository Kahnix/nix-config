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
let
  streamDisplayMode = pkgs.writeShellScript "stream-display-mode" ''
    set -eu
    mode="$1"
    niri="${pkgs.niri}/bin/niri"

    "$niri" msg output HDMI-A-2 mode "$mode"
    "$niri" msg output HDMI-A-2 off
    trap '"$niri" msg output HDMI-A-2 on' EXIT
    "$niri" msg output HDMI-A-2 on
    trap - EXIT
  '';

  # Portable wrapper derivation: bakes niri.kdl into the package (validated
  # via `niri validate` at build time) and points niri at it via NIRI_CONFIG,
  # instead of relying on home-manager to place ~/.config/niri/config.kdl.
  wrappedNiri = inputs.wrapper-modules.wrappers.niri.wrap {
    inherit pkgs;
    "config.kdl".content = builtins.readFile ../../home/kacper/niri.kdl;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gaming.nix
    ../../modules/virtualisation.nix
    inputs.noctalia-greeter.nixosModules.default
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
    firewall.interfaces.tailscale0 = {
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
  services.xserver.videoDrivers = [ "nvidia" ];

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
    droidcam.enable = true;
    niri = {
      enable = true;
      package = wrappedNiri;
    };
    noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "Niri";
        user.default = username;

        appearance = {
          scheme = "Synced";
          password_style = "default";
          hide_logo = false;
          theme_mode = "dark";
          corner_radius_scale = 0.85;
          font_family = "Berkeley Mono";

          palette = {
            primary = "#7e9cd8";
            on_primary = "#111116";
            secondary = "#7fb4ca";
            on_secondary = "#111116";
            tertiary = "#98bb6c";
            on_tertiary = "#111116";
            error = "#e46876";
            on_error = "#111116";
            surface = "#111116";
            on_surface = "#dcd7ba";
            surface_variant = "#1f1f28";
            on_surface_variant = "#a6a69c";
            outline = "#363646";
            shadow = "#090910";
            hover = "#e6c384";
            on_hover = "#111116";
          };

          wallpaper = {
            path = "/home/kacper/Documents/wallpapers/lunar-tides-3440x1440-26444.jpg";
            fill_mode = "crop";
          };
        };

        idle.timeout = 300;

        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };

        keyboard = {
          layout = "us";
          numlock = true;
        };

        auth.allow_empty_password = false;
      };
    };
    nix-ld.enable = true;
  };

  services = {
    displayManager.sddm.enable = false;
    desktopManager.plasma6.enable = false;

    sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = false;

      applications = {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = [
          {
            name = "Desktop";
            "image-path" = "desktop.png";
            "prep-cmd" = [
              {
                do = "${streamDisplayMode} 1680x1050@59.954";
                undo = "${streamDisplayMode} 3440x1440@59.973";
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
        PermitRootLogin = "no";
      };
    };

    tailscale.enable = true;
    usbmuxd.enable = true;
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

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
    ];
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
      wget
    ];
  };

  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    # Berkeley Mono is installed natively per machine, not by Nix.
    fontconfig.defaultFonts = {
      monospace = [ "Berkeley Mono" ];
      sansSerif = [ "Inter" ];
    };
  };

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
