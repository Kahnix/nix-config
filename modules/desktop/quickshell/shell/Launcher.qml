import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Spotlight-style picker over a dimmed screen. Two modes share it: apps
// (Super+Space) and clipboard history (Super+Ctrl+V); Tab switches between them.
PanelWindow {
  id: win

  readonly property bool clipboard: Ui.launcherMode === "clipboard"
  property string query: ""
  property int selected: 0
  readonly property var results: clipboard
    ? Clipboard.items.filter(i => i.text.toLowerCase().includes(query.trim().toLowerCase())).slice(0, 60)
    : Apps.search(query, 40)

  screen: Ui.activeScreen
  visible: Ui.launcherOpen
  color: Theme.scrim
  WlrLayershell.namespace: "qs-launcher"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }

  onVisibleChanged: {
    if (!visible) return;
    query = "";
    input.text = "";
    selected = 0;
    if (clipboard) Clipboard.refresh();
    input.forceActiveFocus();
  }
  onClipboardChanged: {
    selected = 0;
    if (clipboard) Clipboard.refresh();
  }
  onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))

  function accept() {
    const item = results[selected];
    if (!item) return;
    Ui.launcherOpen = false;
    if (clipboard) Clipboard.copy(item);
    else Apps.launch(item);
  }

  function move(step) {
    if (results.length === 0) return;
    selected = (selected + step + results.length) % results.length;
    list.positionViewAtIndex(selected, ListView.Contain);
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Ui.launcherOpen = false
  }

  Rectangle {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(parent.height * 0.2)
    width: 600
    height: 64 + (win.results.length > 0 ? Math.min(win.results.length, 8) * 52 + 12 : 0)
    radius: Theme.radius + 4
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    clip: true

    opacity: win.visible ? 1 : 0
    scale: win.visible ? 1 : 0.97
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // Swallow clicks so they don't reach the close-on-click backdrop.
    MouseArea { anchors.fill: parent }

    RowLayout {
      id: header
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 64
      anchors.leftMargin: 20
      anchors.rightMargin: 14
      spacing: 12

      Glyph {
        glyph: win.clipboard ? Theme.iClipboard : Theme.iSearch
        size: 18
        color: Theme.accent
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        TextInput {
          id: input
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter
          color: Theme.bright
          selectionColor: Theme.alpha(Theme.accent, 0.4)
          font.family: Theme.sans
          font.pixelSize: 17
          clip: true
          onTextChanged: { win.query = text; win.selected = 0; list.positionViewAtBeginning(); }

          Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) Ui.launcherOpen = false;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.accept();
            else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) win.move(1);
            else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) win.move(-1);
            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
              Ui.launcherMode = win.clipboard ? "apps" : "clipboard";
            else if (win.clipboard && event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
              const item = win.results[win.selected];
              if (item) Clipboard.remove(item);
            } else return;
            event.accepted = true;
          }
        }

        Label {
          anchors.fill: parent
          visible: input.text === ""
          text: win.clipboard ? "Search clipboard" : "Search apps"
          color: Theme.faint
          size: 17
        }
      }

      // Mode switch; Tab does the same.
      Rectangle {
        implicitWidth: modeRow.implicitWidth + 8
        implicitHeight: 30
        radius: 15
        color: Theme.alpha(Theme.text, 0.06)

        Row {
          id: modeRow
          anchors.centerIn: parent
          spacing: 2

          Repeater {
            model: [{ mode: "apps", glyph: Theme.iApps }, { mode: "clipboard", glyph: Theme.iClipboard }]

            Rectangle {
              required property var modelData
              readonly property bool current: Ui.launcherMode === modelData.mode
              width: 34
              height: 24
              radius: 12
              color: current ? Theme.alpha(Theme.accent, 0.25) : "transparent"
              Glyph {
                anchors.centerIn: parent
                glyph: modelData.glyph
                size: 14
                color: parent.current ? Theme.accent : Theme.muted
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { Ui.launcherMode = modelData.mode; input.forceActiveFocus(); }
              }
            }
          }
        }
      }
    }

    Rectangle {
      anchors.top: header.bottom
      width: parent.width
      height: 1
      color: Theme.border
      visible: win.results.length > 0
    }

    ListView {
      id: list
      anchors.top: header.bottom
      anchors.topMargin: 6
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 6
      clip: true
      model: win.results
      currentIndex: win.selected
      boundsBehavior: Flickable.StopAtBounds
      highlightMoveDuration: 0

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index
        readonly property bool current: index === win.selected

        width: list.width
        height: 52
        radius: Theme.radiusSmall
        color: current ? Theme.alpha(Theme.accent, 0.16) : rowMouse.containsMouse ? Theme.hover : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 14
          spacing: 12

          IconImage {
            visible: !win.clipboard
            implicitSize: 30
            source: win.clipboard ? "" : Quickshell.iconPath(row.modelData.icon, "application-x-executable")
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
              Layout.fillWidth: true
              text: win.clipboard ? Clipboard.preview(row.modelData) : row.modelData.name
              color: row.current ? Theme.bright : Theme.text
              size: win.clipboard ? 13 : 14
              maximumLineCount: 1
            }
            Label {
              Layout.fillWidth: true
              visible: !win.clipboard && text !== ""
              text: win.clipboard ? "" : (row.modelData.genericName || row.modelData.comment || "")
              color: Theme.muted
              size: Theme.fontSmall
            }
          }

          Label {
            visible: row.current
            text: win.clipboard ? "copy ↵" : "open ↵"
            monospace: true
            size: Theme.fontSmall
            color: Theme.faint
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: { win.selected = row.index; win.accept(); }
        }
      }
    }
  }
}
