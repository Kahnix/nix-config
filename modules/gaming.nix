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
    lutris
    mangohud
    prismlauncher
    protonup-qt
    wineWow64Packages.staging
    winetricks
  ];
}
