import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces for one monitor: clean numbered pills without window icons.
// Active is highlighted with an accent pill; occupied shows a subtle dot
// underneath; urgent turns red. Shows 1..5 at least, more when higher ones
// are in use.
Row {
  id: root

  required property HyprlandMonitor monitor
  readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
  readonly property int shown: {
    let highest = 5;
    const all = Hyprland.workspaces.values;
    for (let i = 0; i < all.length; i++)
      if (all[i].id > highest && all[i].id <= 10) highest = all[i].id;
    return Math.max(highest, activeId > 10 ? 0 : activeId);
  }

  spacing: 4
  height: Theme.barHeight - 10

  Repeater {
    model: root.shown

    Item {
      id: cell

      required property int index
      readonly property int wsId: index + 1
      readonly property HyprlandWorkspace ws: Ui.find(Hyprland.workspaces.values, w => w.id === wsId)
      readonly property var windows: ws ? Array.from(ws.toplevels.values) : []
      readonly property bool active: root.activeId === wsId
      readonly property bool urgent: windows.some(t => t.urgent)
      readonly property bool occupied: windows.length > 0

      width: active ? 30 : 24
      height: parent.height
      Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: cell.urgent ? Theme.alpha(Theme.danger, 0.25)
          : cell.active ? Theme.alpha(Theme.accent, 0.22)
          : mouse.containsMouse ? Theme.hover
          : cell.occupied ? Theme.alpha(Theme.text, 0.06)
          : "transparent"
        border.width: cell.active || cell.urgent ? 1 : 0
        border.color: cell.urgent ? Theme.alpha(Theme.danger, 0.5) : Theme.alpha(Theme.accent, 0.35)
        Behavior on color { ColorAnimation { duration: Theme.anim } }
      }

      Label {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: cell.occupied && !cell.active ? -1 : 0
        monospace: true
        size: 11
        text: cell.wsId
        font.weight: cell.active ? Font.Bold : cell.occupied ? Font.DemiBold : Font.Normal
        color: cell.urgent ? Theme.danger
          : cell.active ? Theme.accent
          : cell.occupied ? Theme.text
          : mouse.containsMouse ? Theme.muted : Theme.faint
      }

      // Subtle occupied dot when inactive.
      Rectangle {
        visible: cell.occupied && !cell.active
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: 4
        height: 2
        radius: 1
        color: cell.urgent ? Theme.danger : Theme.alpha(Theme.accent, 0.7)
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.dispatch("hl.dsp.focus({ workspace = " + cell.wsId + " })")
      }
    }
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => Ui.dispatch("hl.dsp.focus({ workspace = '" + (event.angleDelta.y > 0 ? "e-1" : "e+1") + "' })")
  }
}
