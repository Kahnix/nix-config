{ applyPatches, fetchFromGitHub }:

# DMS Docker Manager plugin, pinned; the patch hides the bar widget when the
# container runtime is absent. Update here, not with `dms plugins update`.
applyPatches {
  name = "dms-docker-manager";
  src = fetchFromGitHub {
    owner = "LuckShiba";
    repo = "DmsDockerManager";
    rev = "f6f7d94c84510da098980a2bb733137e90f98fd8";
    hash = "sha256-KEj0d1K0+ZOxbQ9FLzapWZ82i31hbpEHUAOZfJF8IGs=";
  };
  patches = [ ./docker-manager-visibility.patch ];
}
