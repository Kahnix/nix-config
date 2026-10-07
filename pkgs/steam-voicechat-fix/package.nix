{ fetchFromGitHub, runCommandCC }:

# Steam's 32-bit client dies when a non-Steam player speaks in CS 1.6's voice
# chat: the client's SILK/Speex decoder clobbers EBX (which i386 PIC code must
# keep pointing at the GOT) and then calls memmove through its EBX-relative PLT
# stub, so the indirect jump reads a decoded-voice buffer and lands on garbage
# (ValveSoftware/halflife#3895 / #3898, open and unfixed upstream).
#
# This preload rewrites that one stub into a direct jump to memmove, inside the
# Steam client process only -- it no-ops unless /proc/self/exe is `steam`, so
# game processes stay untouched. Upstream ships no license file, so the source
# is fetched pinned instead of vendored here.
let
  src = fetchFromGitHub {
    owner = "hilorioze";
    repo = "steam-voicechat-fix";
    rev = "41cfcd5513934611cf678d0ad5933c38deba01b7";
    hash = "sha256-yeogyBMX6ZzCH5YL2J+PNe7jRZfKEpfV9oIK2Juki8Y=";
  };
in
runCommandCC "steam-voicechat-fix" { } ''
  mkdir -p $out/lib
  $CC -shared -fPIC -O2 -Wall -Wextra -Werror \
    ${src}/src/voicechat_fix.c \
    -o $out/lib/libsteam_voicechat_fix.so \
    -lpthread
''
