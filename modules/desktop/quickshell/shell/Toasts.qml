import QtQuick
import Quickshell
import Quickshell.Wayland

// Toast stack under the bar's right end, on the focused monitor.
PanelWindow {
  screen: Ui.activeScreen
  visible: Notifs.popups.length > 0 && !Ui.controlOpen
  color: "transparent"
  WlrLayershell.namespace: "qs-toast"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; right: true }
  margins.top: Theme.barHeight + Theme.gap * 2
  margins.right: Theme.edge
  implicitWidth: 380
  implicitHeight: Math.max(1, stack.implicitHeight)

  Column {
    id: stack
    width: parent.width
    spacing: Theme.gap

    Repeater {
      model: Notifs.popups

      NotificationCard {
        required property var modelData
        width: stack.width
        notification: modelData
        popup: true
      }
    }
  }
}
