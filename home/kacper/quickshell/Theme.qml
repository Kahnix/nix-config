pragma Singleton

import QtQuick

QtObject {
  readonly property color base: "#111116"
  readonly property color surface: Qt.rgba(0.09, 0.09, 0.12, 0.95)
  readonly property color surfaceRaised: Qt.rgba(0.12, 0.12, 0.16, 0.97)
  readonly property color border: "#363646"
  readonly property color text: "#dcd7ba"
  readonly property color muted: "#727169"
  readonly property color blue: "#7e9cd8"
  readonly property color green: "#98bb6c"
  readonly property color coral: "#e46876"
  readonly property color yellow: "#e6c384"
  readonly property color scrim: Qt.rgba(0.04, 0.05, 0.07, 0.36)

  readonly property string font: "Departure Mono"
  readonly property int radius: 4
  readonly property int borderWidth: 1
  readonly property int barHeight: 38
  readonly property int outerGap: 8
}
