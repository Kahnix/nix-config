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

  woMicBuffer =
    pkgs.runCommandCC "wo-mic-buffer"
      {
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.alsa-lib ];
      }
      ''
        mkdir -p "$out/lib"
        $CC -shared -fPIC -O2 -Wall -Wextra -Werror \
          $(pkg-config --cflags alsa) ${./wo-mic-buffer.c} \
          -o "$out/lib/libwo-mic-buffer.so" \
          $(pkg-config --libs alsa) -ldl -pthread
      '';

  woMic = pkgs.appimageTools.wrapType2 {
    pname = "wo-mic";
    version = "4.6";
    src = pkgs.fetchurl {
      url = "https://wolicheng.com/womic/softwares/micclient-x86_64.AppImage";
      hash = "sha256-6g7IhgHWncuqImuUwfmDefkMEWqp5+3y/RJHviV+Hbs=";
    };
    extraPkgs = appimagePkgs: [
      appimagePkgs.alsa-lib
      appimagePkgs.bluez
    ];
    profile = ''
      export LD_PRELOAD="${woMicBuffer}/lib/libwo-mic-buffer.so''${LD_PRELOAD:+:$LD_PRELOAD}"
    '';
  };

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
    overlays = [
      inputs.nix-cachyos-kernel.overlays.pinned
      (_final: prev: {
        # 0.8.2 immediately dismisses Steam popup menus under Niri.
        # Remove after https://github.com/Supreeeme/xwayland-satellite/issues/435 is fixed in a release.
        xwayland-satellite =
          let
            src = prev.fetchFromGitHub {
              owner = "Supreeeme";
              repo = "xwayland-satellite";
              tag = "v0.8.1";
              hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
            };
          in
          prev.xwayland-satellite.overrideAttrs {
            version = "0.8.1";
            inherit src;
            cargoDeps = prev.rustPlatform.fetchCargoVendor {
              inherit src;
              hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
            };
          };
      })
    ];
  };

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    blacklistedKernelModules = [ "nouveau" ];
    kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    kernelModules = [ "snd-aloop" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.interfaces.enp7s0.allowedUDPPorts = [ 49152 ];
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
    # GPU Screen Recorder: the module installs the CLI plus a setcap'd
    # gsr-kms-server wrapper, which direct monitor (KMS) capture requires.
    gpu-screen-recorder.enable = true;
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
          font_family = config.stylix.fonts.monospace.name;

          palette = with config.lib.stylix.colors.withHashtag; {
            primary = base0D;
            on_primary = base00;
            secondary = base0C;
            on_secondary = base00;
            tertiary = base0B;
            on_tertiary = base00;
            error = base08;
            on_error = base00;
            surface = base00;
            on_surface = base05;
            surface_variant = base01;
            on_surface_variant = base04;
            outline = base02;
            shadow = base00;
            hover = base0A;
            on_hover = base00;
          };

          wallpaper = {
            path = "/home/kacper/Documents/wallpapers/lunar-tides-3440x1440-26444.jpg";
            fill_mode = "crop";
          };
        };

        idle.timeout = 300;

        cursor = {
          theme = config.stylix.cursor.name;
          size = config.stylix.cursor.size;
          path = "${config.stylix.cursor.package}/share/icons";
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

    # WO Mic outputs 48 kHz, 16-bit mono PCM to the ALSA loopback device.
    # Keeping PipeWire at 48 kHz avoids an unnecessary resampling step.
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack.enable = true;
      pulse.enable = true;
      wireplumber.extraConfig."51-wo-mic-loopback" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.name" = "alsa_card.platform-snd_aloop.0"; }
            ];
            actions."update-props"."device.disabled" = true;
          }
        ];
      };
      extraConfig = {
        pipewire."10-clock-rate"."context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 48000 ];
        };
        pipewire-pulse."50-wo-mic-audio"."pulse.cmd" = [
          {
            cmd = "load-module";
            args = "module-alsa-source source_name=wo_mic source_properties=device.description=WO-Mic channels=1 rate=48000 format=s16le device=hw:Loopback,1,0 fragments=8 fragment_size=1920";
            flags = [ "nofail" ];
          }
        ];
      };
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
    udisks2.enable = true;
    upower.enable = true;
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;

    logind.settings.Login = {
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
      HandlePowerKey = "ignore";
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
    AllowSuspend = true;
    AllowHibernation = true;
    AllowHybridSleep = true;
    AllowSuspendThenHibernate = true;
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

  # 16 GiB RAM and no disk swap: give the kernel a compressed eviction target, so
  # a large working set (game plus its Proton prefix) cannot only end in an OOM
  # kill. lz4 decompresses ~3x faster than the default zstd, which is the trade
  # that matters when swapped pages are faulted back in mid-frame.
  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };

  environment = {
    # nixpkgs defaults EDITOR to `nano` with lib.mkDefault; a plain assignment
    # wins. This is what yazi's built-in `edit` opener runs ("${EDITOR:-vi} %s",
    # blocking), and what git, ssh and everything else picks up.
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      LIBVA_DRIVER_NAME = "nvidia";
      NIXOS_OZONE_WL = "1";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    systemPackages = with pkgs; [
      woMic
      curl
      git
      pciutils
      tailscale
      wget
    ];
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
