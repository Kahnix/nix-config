pragma Singleton

import QtQuick
import Quickshell

// Semantic colours, sizes and glyphs. Raw Stylix values come from Stylix.qml,
// which quickshell.nix generates from the active Base16 scheme.
Singleton {
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

  readonly property color bg: Stylix.base00
  readonly property color surface: alpha(Stylix.base01, Math.min(Stylix.opacity, 0.84))
  readonly property color card: alpha(Stylix.base02, 0.45)
  readonly property color cardBorder: alpha(Stylix.base05, 0.08)
  readonly property color raised: Stylix.base02
  readonly property color hover: alpha(Stylix.base05, 0.08)
  readonly property color border: alpha(Stylix.base05, 0.12)
  readonly property color text: Stylix.base05
  readonly property color bright: Stylix.base07
  readonly property color muted: Stylix.base04
  readonly property color faint: Stylix.base03
  readonly property color accent: Stylix.base0D
  readonly property color accentAlt: Stylix.base0C
  readonly property color good: Stylix.base0B
  readonly property color warn: Stylix.base0A
  readonly property color danger: Stylix.base08
  readonly property color scrim: alpha(Stylix.base00, 0.28)

  readonly property string sans: Stylix.sans
  readonly property string mono: Stylix.mono
  readonly property int fontSize: 13
  readonly property int fontSmall: 11

  readonly property int barHeight: 38
  readonly property int gap: 8
  // Matches Hyprland's gaps_out, so the bar lines up with window edges.
  readonly property int edge: 12
  readonly property int radius: 12
  readonly property int radiusSmall: 8
  readonly property int anim: 180

  // 0..100 usage to a calm-to-alarm colour.
  function level(percent) {
    if (percent >= 85) return danger;
    if (percent >= 60) return warn;
    return good;
  }

  // Nerd Font Material Design glyphs (Berkeley Mono Nerd Font carries them).
  function g(cp) { return String.fromCodePoint(cp); }
  readonly property string iNix: ""
  readonly property string iVolHigh: g(0xF057E)
  readonly property string iVolMid: g(0xF0580)
  readonly property string iVolLow: g(0xF057F)
  readonly property string iVolOff: g(0xF0581)
  readonly property string iMic: g(0xF036C)
  readonly property string iMicOff: g(0xF036D)
  readonly property string iBell: g(0xF009A)
  readonly property string iBellOff: g(0xF009B)
  readonly property string iPower: g(0xF0425)
  readonly property string iLock: g(0xF033E)
  readonly property string iLogout: g(0xF0343)
  readonly property string iRestart: g(0xF0709)
  readonly property string iSleep: g(0xF04B2)
  readonly property string iPlay: g(0xF040A)
  readonly property string iPause: g(0xF03E4)
  readonly property string iNext: g(0xF04AD)
  readonly property string iPrev: g(0xF04AE)
  readonly property string iRecord: g(0xF044A)
  readonly property string iStop: g(0xF04DB)
  readonly property string iBluetooth: g(0xF00AF)
  readonly property string iCoffee: g(0xF0176)
  readonly property string iSearch: g(0xF0349)
  readonly property string iClipboard: g(0xF0192)
  readonly property string iClose: g(0xF0156)
  readonly property string iTrash: g(0xF0A79)
  readonly property string iRefresh: g(0xF0450)
  readonly property string iRobot: g(0xF06A9)
  readonly property string iMusic: g(0xF075A)
  readonly property string iApps: g(0xF003B)
  readonly property string iWifi: g(0xF05A9)
  readonly property string iWifiOff: g(0xF05AA)
  readonly property string iEthernet: g(0xF0200)
  readonly property string iCalendar: g(0xF00ED)
  readonly property string iCamera: g(0xF0100)
  readonly property string iCpu: g(0xF0EE0)
  readonly property string iMem: g(0xF035B)
  readonly property string iGpu: g(0xF061A)
  readonly property string iSun: g(0xF0599)
  readonly property string iMoon: g(0xF0594)
  readonly property string iCloud: g(0xF0590)
  readonly property string iRain: g(0xF0597)
  readonly property string iSnow: g(0xF0598)
  readonly property string iStorm: g(0xF0593)
  readonly property string iChevronLeft: g(0xF0141)
  readonly property string iChevronRight: g(0xF0142)
  readonly property string iDashboard: g(0xF056E)
  readonly property string iMonitor: g(0xF0379)
  readonly property string iImage: g(0xF02E9)
  readonly property string iTune: g(0xF062E)
  readonly property string iFolder: g(0xF024B)
  readonly property string iGauge: g(0xF029A)
  readonly property string iCheck: g(0xF012C)
  readonly property string iVpn: g(0xF0582)
  readonly property string iDocker: g(0xF0868)
  readonly property string iCopy: g(0xF018F)
  readonly property string iServer: g(0xF048B)
}
