{
  alsa-lib,
  appimageTools,
  fetchurl,
  pkg-config,
  runCommandCC,
}:

let
  # WO Mic-only ALSA buffering fix: playback waits for three 20 ms packets
  # before starting, so a single late packet no longer underruns.
  buffer =
    runCommandCC "wo-mic-buffer"
      {
        nativeBuildInputs = [ pkg-config ];
        buildInputs = [ alsa-lib ];
      }
      ''
        mkdir -p "$out/lib"
        $CC -shared -fPIC -O2 -Wall -Wextra -Werror \
          $(pkg-config --cflags alsa) ${./wo-mic-buffer.c} \
          -o "$out/lib/libwo-mic-buffer.so" \
          $(pkg-config --libs alsa) -ldl -pthread
      '';
in
appimageTools.wrapType2 {
  pname = "wo-mic";
  version = "4.6";
  src = fetchurl {
    url = "https://wolicheng.com/womic/softwares/micclient-x86_64.AppImage";
    hash = "sha256-6g7IhgHWncuqImuUwfmDefkMEWqp5+3y/RJHviV+Hbs=";
  };
  extraPkgs = appimagePkgs: [
    appimagePkgs.alsa-lib
    appimagePkgs.bluez
  ];
  profile = ''
    export LD_PRELOAD="${buffer}/lib/libwo-mic-buffer.so''${LD_PRELOAD:+:$LD_PRELOAD}"
  '';
}
