{
  lib,
  stdenv,
  writeShellApplication,
  runCommand,
  writeText,
  libarchive,
  virtio-win,
  qemu,
  qemu_kvm,
  syncthing,
  xorriso,
  socat,
  openssh,
  curl,
  jq,
  coreutils,
  gnused,
  gnugrep,
  freerdp,
}:

# `winvm`: an unattended Windows 11 Pro VM (ARM64 under HVF on Apple Silicon,
# x64 under KVM on Linux) with the Tauri/Windows toolchain, a two-way Syncthing
# mirror of one host folder, and headless build/test/run from the host shell.
# State lives under ~/.local/share/winvm, the ISO under ~/.cache/winvm.
let
  guestArch = if stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";

  # Both ship the edk2 firmware under share/qemu; qemu_kvm is what
  # modules/virtualisation.nix already uses.
  qemuPkg = if stdenv.hostPlatform.isDarwin then qemu else qemu_kvm;

  # Windows 11 25H2 (26200.6584), en-us consumer. Downloaded at runtime into
  # the cache dir: a 7 GB store path would stay in the system closure forever.
  isoBase = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENT_CONSUMER";
  iso =
    {
      arm64 = {
        url = "${isoBase}_a64fre_en-us.iso";
        sha256 = "32cde0071ed8086b29bb6c8c3bf17ba9e3cdf43200537434a811a9b6cc2711a1";
        size = "7299147776";
      };
      amd64 = {
        url = "${isoBase}_x64FRE_en-us.iso";
        sha256 = "d141f6030fed50f75e2b03e1eb2e53646c4b21e5386047cb860af5223f102a32";
        size = "7736125440";
      };
    }
    .${guestArch};

  # <driver>/w11/<ARM64|amd64>/ from the Fedora virtio-win ISO (NetKVM etc.).
  # virtio-win itself is Linux-only, but its src evaluates everywhere.
  driverDir = if guestArch == "arm64" then "ARM64" else "amd64";
  # The ISO stores w11/ files as hardlinks into 2k25/, so a filtered extract
  # would miss the link targets: unpack everything, then keep w11/<arch>.
  drivers = runCommand "winvm-virtio-${guestArch}" { nativeBuildInputs = [ libarchive ]; } ''
    mkdir all $out
    bsdtar -xf ${virtio-win.src} -C all
    chmod -R u+w all
    (cd all && cp --parents -R --no-preserve=mode */w11/${driverDir} $out/)
  '';

  tools = writeText "winvm-tools.json" (
    builtins.toJSON ((import ./tools.nix { inherit lib; }).${guestArch})
  );

  data = runCommand "winvm-data" { } ''
    mkdir -p $out
    cp -R --no-preserve=mode ${./guest} $out/guest
    cp --no-preserve=mode ${./autounattend.xml} $out/autounattend.xml
    cp --no-preserve=mode ${./syncthing-config.xml} $out/syncthing-config.xml
    cp --no-preserve=mode ${./syncthing-folder.xml} $out/syncthing-folder.xml
    cp --no-preserve=mode ${./stignore} $out/stignore
    cp --no-preserve=mode ${tools} $out/guest/tools.json
    ln -s ${drivers} $out/drivers
  '';
in
writeShellApplication {
  name = "winvm";
  runtimeInputs = [
    qemuPkg
    syncthing
    xorriso
    socat
    openssh
    curl
    jq
    coreutils
    gnused
    gnugrep
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux freerdp;
  runtimeEnv = {
    WINVM_DATA = data;
    WINVM_QEMU_SHARE = "${qemuPkg}/share/qemu";
    WINVM_GUEST_ARCH = guestArch;
    WINVM_ISO_URL = iso.url;
    WINVM_ISO_SHA256 = iso.sha256;
    WINVM_ISO_SIZE = iso.size;
  };
  text = builtins.readFile ./winvm.sh;
  meta = {
    description = "Unattended Windows 11 VM with live folder sync for building and testing";
    mainProgram = "winvm";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
