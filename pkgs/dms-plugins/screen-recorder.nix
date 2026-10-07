{ applyPatches, fetchFromGitHub }:

# DMS Screen Recorder plugin, pinned, with a Vulkan encoder choice for NVIDIA 580.
# Update the rev and patch here, not with `dms plugins update screenRecorder`.
applyPatches {
  name = "dms-screen-recorder";
  src = fetchFromGitHub {
    owner = "arqueon";
    repo = "dms-screen-recorder";
    rev = "1e25de9d16e63871d53b21127d31af026fa60cd6";
    hash = "sha256-Q0NgtSpP74Gpx5LJWslqcBuVZ2jrjpY+2Ae1sBId6Fs=";
  };
  patches = [ ./screen-recorder-codec.patch ];
}
