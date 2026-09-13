{ pkgs, ... }:
let
  boltLauncher = pkgs.symlinkJoin {
    name = "bolt-launcher-with-audio";
    paths = [ pkgs.bolt-launcher ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/bolt-launcher" \
        --set JAVA_TOOL_OPTIONS \
          "-Djavax.sound.sampled.Clip='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]' -Djavax.sound.sampled.SourceDataLine='com.sun.media.sound.DirectAudioDeviceProvider#alsa_playback.java [default]'"
    '';
  };

  pythonA2s = pkgs.python313Packages.buildPythonPackage {
    pname = "python-a2s";
    version = "1.4.1";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Yepoleb";
      repo = "python-a2s";
      rev = "b40eb24cdbb06ebd08272f224257fe5a81610e86";
      hash = "sha256-UGzHpU3ara9fAFhMJHJq5dhttHMC/xColR4fGL3JYmA=";
    };

    build-system = [ pkgs.python313Packages.setuptools ];
  };

  dayzquery = pkgs.python313Packages.buildPythonPackage {
    pname = "dayzquery";
    version = "1.3.1";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Yepoleb";
      repo = "dayzquery";
      rev = "07483b88ed096327ebca752f5e177011b604d7fe";
      hash = "sha256-HH8TRnPwWBSkfmG245lbVG3tN6VbsRl/7YEg07Kzptg=";
    };

    build-system = [ pkgs.python313Packages.setuptools ];
    dependencies = [ pythonA2s ];
  };

  dzguiDesktop = pkgs.makeDesktopItem {
    name = "dzgui";
    desktopName = "DZGUI";
    comment = "DayZ server browser and mod manager";
    exec = "dzgui";
    icon = "dzgui";
    startupNotify = true;
    startupWMClass = "DZGUI";
    categories = [ "Game" ];
  };

  dzgui = pkgs.python313Packages.buildPythonApplication {
    pname = "dzgui";
    version = "7.0.0b24";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "aclist";
      repo = "dztui";
      tag = "7.0.0b24";
      hash = "sha256-f9wptx1XmBPYy4O9xHQn8M9BJ0CcmDrjJahrd3X7csE=";
    };

    postPatch = ''
      substituteInPlace dzgui/const/update.py \
        --replace-fail "ALLOW_UPDATES = True" "ALLOW_UPDATES = False"
    '';

    build-system = with pkgs.python313Packages; [
      setuptools
      setuptools-scm
    ];

    nativeBuildInputs = [
      pkgs.gobject-introspection
      pkgs.wrapGAppsHook3
    ];

    buildInputs = [ pkgs.gtk3 ];

    dependencies = with pkgs.python313Packages; [
      dayzquery
      packaging
      psutil
      pygobject3
      pythonA2s
      requests
      vdf
    ];

    pythonRelaxDeps = [
      "packaging"
      "psutil"
      "pygobject"
      "requests"
    ];

    postInstall = ''
      install -Dm644 dzgui/data/images/icon.png \
        "$out/share/icons/hicolor/256x256/apps/dzgui.png"
      install -Dm644 ${dzguiDesktop}/share/applications/dzgui.desktop \
        "$out/share/applications/dzgui.desktop"
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.glib ]}
      )
    '';

    meta = {
      description = "DayZ server browser and mod manager for Linux";
      homepage = "https://aclist.github.io/dzgui";
      license = pkgs.lib.licenses.gpl3Plus;
      mainProgram = "dzgui";
      platforms = [ "x86_64-linux" ];
    };
  };

  # CachyOS Proton is not packaged in nixpkgs; it ships Steam Linux Runtime
  # tarballs as GitHub release assets. Same shape as proton-ge-bin so it can go
  # through programs.steam.extraCompatPackages.
  #
  # The x86_64_v3 asset needs AVX2/BMI2/FMA (Zen 2+ / Haswell+); it is built for
  # the Ryzen 3700X in this host. The plain x86_64 asset is the portable fallback.
  protonCachyOS = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "proton-cachyos-bin";
    version = "11.0-20260703";

    src = pkgs.fetchzip {
      url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-${finalAttrs.version}-slr/proton-cachyos-${finalAttrs.version}-slr-x86_64_v3.tar.xz";
      hash = "sha256-8Y7orUvnFOG0zSqCrMyvmclmy3JInj7d8A2h0Y7RwhE=";
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    outputs = [
      "out"
      "steamcompattool"
    ];

    installPhase = ''
      runHook preInstall

      # Refuse to be part of an environment; the NixOS option is the supported path.
      echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

      mkdir $steamcompattool
      ln -s $src/* $steamcompattool

      # Replace the symlink with a writable copy; substituteInPlace cannot edit
      # a read-only store file (same approach as pkgs.proton-ge-bin).
      rm $steamcompattool/compatibilitytool.vdf
      cp $src/compatibilitytool.vdf $steamcompattool

      runHook postInstall
    '';

    preFixup = ''
      # Keep the versioned internal name (Steam maps per-game compat tools by it),
      # but show a readable entry in the Properties -> Compatibility dropdown.
      substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
        --replace-fail \
          "\"display_name\" \"proton-cachyos-${finalAttrs.version}-slr-x86_64_v3\"" \
          "\"display_name\" \"Proton-CachyOS\""
    '';

    meta = {
      description = "Compatibility tool for Steam Play based on Wine and additional components (CachyOS builds)";
      homepage = "https://github.com/CachyOS/proton-cachyos";
      license = pkgs.lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  });
in
{
  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
      protonCachyOS
    ];
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    boltLauncher
    dzgui
    lutris
    mangohud
    prismlauncher
    protonup-qt
    wineWow64Packages.staging
    winetricks
  ];
}
