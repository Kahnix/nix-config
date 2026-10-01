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
    output="HDMI-A-2"

    # Lua-configured Hyprland uses eval for runtime monitor changes.
    "${config.programs.hyprland.package}/bin/hyprctl" eval \
      "hl.monitor({ output = '$output', mode = '$mode' })"
  '';

  # Moonlight app list. Sunshine reads it from its appdata path
  # (~/.config/sunshine/apps.json) unless the config pins file_apps, and that
  # default path is what a launcher-started `sunshine` (not the systemd unit)
  # also loads. Feed the same definition to both.
  sunshineApplications = {
    env.PATH = "$(PATH):$(HOME)/.local/bin";
    apps = [
      {
        name = "Desktop";
        "image-path" = "desktop.png";
        "prep-cmd" = [
          {
            do = "${streamDisplayMode} 1680x1050@59.954";
            # Restore the desktop's configured ultrawide refresh rate.
            undo = "${streamDisplayMode} 3440x1440@99.982";
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

  sunshineAppsJson = (pkgs.formats.json { }).generate "sunshine-apps.json" sunshineApplications;

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
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gaming.nix
    ../../modules/virtualisation.nix
  ];

  nixpkgs = {
    hostPlatform = system;
    overlays = [
      inputs.nix-cachyos-kernel.overlays.pinned
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
  # AT-SPI bus. omp's computer use enumerates windows and reads accessibility
  # trees over it; without the bus those calls fail with the nixpkgs-documented
  # "org.a11y.Bus was not provided by any .service files".
  services.gnome.at-spi2-core.enable = true;

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
      "docker"
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
    # UWSM owns the graphical session lifecycle; Home Manager only configures it.
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    # Ensure UWSM registers a session whose instance id is derived from the
    # Hyprland binary itself (not start-hyprland), producing
    # wayland-session@Hyprland.target and wayland-wm@Hyprland.service.
    uwsm.waylandCompositors.hyprland = {
      # NixOS appends " (UWSM)" to prettyName, so the greeter label becomes
      # "Hyprland + Quickshell (UWSM)".
      prettyName = "Hyprland + Quickshell";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/Hyprland";
    };
    nix-ld.enable = true;
  };

  services = {
    displayManager.sddm.enable = false;
    displayManager.defaultSession = "hyprland-uwsm";
    displayManager.dms-greeter = {
      enable = true;
      compositor = {
        name = "hyprland";
        # Separate login compositor: no desktop services or application bindings.
        customConfig = ''
          hl.env("XCURSOR_THEME", "${config.stylix.cursor.name}")
          hl.env("XCURSOR_SIZE", "${toString config.stylix.cursor.size}")
          hl.config({
            misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
            input = { kb_layout = "us", numlock_by_default = true },
          })
        '';
      };
      # The module copies settings, wallpaper and custom theme into the
      # greeter's own directory; login never depends on home-directory access.
      configHome = "/home/${username}";
    };
    desktopManager.plasma6.enable = false;

    sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = false;

      applications = sunshineApplications;
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
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
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
    # DMS lock authenticates against the "dankshell" PAM service. Providing it
    # here lets the shell use system auth instead of its bundled fallback.
    pam.services.dankshell = { };
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

  # Seed the first login selection only; subsequent choices remain writable.
  systemd.tmpfiles.settings."10-dms-greeter" = {
    "/var/lib/dms-greeter/.local/state".d = {
      user = "dms-greeter";
      group = "dms-greeter";
      mode = "0700";
    };
    "/var/lib/dms-greeter/.local/state/memory.json".C = {
      user = "dms-greeter";
      group = "dms-greeter";
      mode = "0600";
      argument = toString (
        pkgs.writeText "dms-greeter-memory.json" (
          builtins.toJSON {
            lastSessionDesktopId = "hyprland-uwsm.desktop";
            lastSuccessfulUser = username;
          }
        )
      );
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
    users.${username} = {
      imports = [ (import ../../home/kacper) ];

      # Sunshine falls back to <appdata>/apps.json when file_apps is unset, which
      # is also the file a launcher-started `sunshine` loads. Same content as the
      # unit's file_apps, so both start modes get the prep-cmd.
      xdg.configFile."sunshine/apps.json".source = sunshineAppsJson;
    };
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    stateVersion = "26.05";
  };
}
