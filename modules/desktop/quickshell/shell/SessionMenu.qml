import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Lock / suspend / log out / reboot / shut down. Arrow keys + Enter, or the
// letter shown on each button; Escape or a click outside cancels.
PanelWindow {
  id: win

  property int selected: 0
  readonly property var actions: [
    { key: "l", label: "Lock", glyph: Theme.iLock, command: ["loginctl", "lock-session"] },
    { key: "s", label: "Suspend", glyph: Theme.iSleep, command: ["systemctl", "suspend"] },
    { key: "e", label: "Log out", glyph: Theme.iLogout, command: ["uwsm", "stop"] },
    { key: "r", label: "Reboot", glyph: Theme.iRestart, command: ["systemctl", "reboot"] },
    { key: "p", label: "Shut down", glyph: Theme.iPower, command: ["systemctl", "poweroff"] }
  ]

  screen: Ui.activeScreen
  visible: Ui.sessionOpen
  color: Theme.alpha(Theme.bg, 0.55)
  WlrLayershell.namespace: "qs-session"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }

  onVisibleChanged: if (visible) { selected = 0; keys.forceActiveFocus(); }

  function run(index) {
    Ui.sessionOpen = false;
    Quickshell.execDetached(actions[index].command);
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Ui.sessionOpen = false
  }

  Item {
    id: keys
    focus: true
    Keys.onPressed: event => {
      const i = win.actions.findIndex(a => a.key === event.text.toLowerCase());
      if (event.key === Qt.Key_Escape) Ui.sessionOpen = false;
      else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) win.selected = (win.selected + 4) % 5;
      else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) win.selected = (win.selected + 1) % 5;
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) win.run(win.selected);
      else if (i >= 0) win.run(i);
      else return;
      event.accepted = true;
    }
  }

  RowLayout {
    anchors.centerIn: parent
    spacing: 16
    opacity: win.visible ? 1 : 0
    scale: win.visible ? 1 : 0.95
    Behavior on opacity { NumberAnimation { duration: Theme.anim } }
    Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    Repeater {
      model: win.actions

      Rectangle {
        id: button
        required property var modelData
        required property int index
        readonly property bool current: index === win.selected
        readonly property color tint: index === 4 ? Theme.danger : Theme.accent

        implicitWidth: 132
        implicitHeight: 132
        radius: Theme.radius + 6
        color: current ? Theme.alpha(tint, 0.2) : Theme.surface
        border.width: 1
        border.color: current ? Theme.alpha(tint, 0.6) : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        ColumnLayout {
          anchors.centerIn: parent
          spacing: 10
          Glyph {
            Layout.alignment: Qt.AlignHCenter
            glyph: button.modelData.glyph
            size: 34
            color: button.current ? button.tint : Theme.text
          }
          Label {
            Layout.alignment: Qt.AlignHCenter
            text: button.modelData.label
            color: button.current ? Theme.bright : Theme.muted
          }
          Label {
            Layout.alignment: Qt.AlignHCenter
            text: button.modelData.key
            monospace: true
            size: Theme.fontSmall
            color: Theme.faint
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: win.selected = button.index
          onClicked: win.run(button.index)
        }
      }
    }
  }
}
