import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Volume pop-up at the bottom of the focused monitor. Click-through.
PanelWindow {
  id: win

  property bool shown: false
  property bool armed: false

  screen: Ui.activeScreen
  visible: shown || pill.opacity > 0
  color: "transparent"
  WlrLayershell.namespace: "qs-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Ignore
  anchors.bottom: true
  margins.bottom: 96
  implicitWidth: 300
  implicitHeight: 52
  mask: Region {}

  function show() {
    if (!armed) return;
    shown = true;
    hideTimer.restart();
  }

  // PipeWire reports the initial volume right after startup; don't show it.
  Timer { interval: 2000; running: true; onTriggered: win.armed = true }
  Timer { id: hideTimer; interval: 1400; onTriggered: win.shown = false }

  Connections {
    target: Audio
    function onVolumeChanged() { win.show(); }
    function onMutedChanged() { win.show(); }
    function onMicMutedChanged() { win.show(); }
  }

  Rectangle {
    id: pill
    anchors.fill: parent
    radius: height / 2
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    opacity: win.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim } }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 20
      anchors.rightMargin: 20
      spacing: 14

      Glyph {
        glyph: Audio.icon(Audio.volume, Audio.muted)
        size: 18
        color: Audio.muted ? Theme.faint : Theme.accent
      }
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.alpha(Theme.text, 0.1)
        Rectangle {
          width: parent.width * Math.min(1, Audio.volume)
          height: parent.height
          radius: parent.radius
          color: Audio.muted ? Theme.faint : Theme.accent
          Behavior on width { NumberAnimation { duration: 90 } }
        }
      }
      Label {
        Layout.preferredWidth: 30
        horizontalAlignment: Text.AlignRight
        monospace: true
        text: Math.round(Audio.volume * 100)
      }
    }
  }
}
