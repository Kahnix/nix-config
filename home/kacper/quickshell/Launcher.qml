import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
  id: root
  required property var shell

  property string query: ""
  property int selectedIndex: 0
  readonly property var filteredApps: {
    const needle = query.trim().toLowerCase();
    const source = DesktopEntries.applications.values;
    const matches = [];

    for (let i = 0; i < source.length; i++) {
      const app = source[i];
      const haystack = [app.name, app.genericName, app.comment, app.keywords.join(" ")].join(" ").toLowerCase();
      if (!needle || haystack.includes(needle)) matches.push(app);
    }

    matches.sort((left, right) => {
      const leftName = left.name.toLowerCase();
      const rightName = right.name.toLowerCase();
      const leftStarts = needle && leftName.startsWith(needle) ? 0 : 1;
      const rightStarts = needle && rightName.startsWith(needle) ? 0 : 1;
      return leftStarts - rightStarts || leftName.localeCompare(rightName);
    });

    return matches.slice(0, 8);
  }

  function launch(index) {
    const app = filteredApps[index];
    if (!app) return;
    app.execute();
    shell.launcherOpen = false;
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: launcherWindow
      required property var modelData
      readonly property var monitor: Hyprland.monitorFor(modelData)

      screen: modelData
      visible: root.shell.launcherOpen && monitor === Hyprland.focusedMonitor
      color: Theme.scrim
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Connections {
        target: root.shell
        function onLauncherOpenChanged() {
          if (root.shell.launcherOpen) {
            root.query = "";
            root.selectedIndex = 0;
            Qt.callLater(() => searchInput.forceActiveFocus());
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.shell.launcherOpen = false
      }

      Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(620, launcherWindow.width - 48)
        height: 84 + Math.max(1, appList.count) * 58
        radius: Theme.radius
        color: Theme.surfaceRaised
        border.width: Theme.borderWidth
        border.color: Theme.border
        opacity: root.shell.launcherOpen ? 1 : 0
        scale: root.shell.launcherOpen ? 1 : 0.97

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        MouseArea {
          anchors.fill: parent
          onClicked: mouse => mouse.accepted = true
        }

        Rectangle {
          id: searchBox
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 14
          }
          height: 46
          radius: Theme.radius
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: searchInput.activeFocus ? Theme.coral : Theme.border

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Theme.muted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 42
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: "Type to search applications"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
          }

          TextInput {
            id: searchInput
            anchors {
              left: parent.left
              leftMargin: 42
              right: parent.right
              rightMargin: 14
              verticalCenter: parent.verticalCenter
            }
            color: Theme.text
            selectionColor: Theme.blue
            selectedTextColor: Theme.base
            font.family: Theme.font
            font.pixelSize: 13
            text: root.query
            onTextChanged: {
              root.query = text;
              root.selectedIndex = 0;
            }

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) {
                root.shell.launcherOpen = false;
                event.accepted = true;
              } else if (event.key === Qt.Key_Down) {
                root.selectedIndex = Math.min(appList.count - 1, root.selectedIndex + 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.launch(root.selectedIndex);
                event.accepted = true;
              }
            }
          }
        }

        ListView {
          id: appList
          anchors {
            top: searchBox.bottom
            topMargin: 10
            bottom: parent.bottom
            bottomMargin: 10
            left: parent.left
            leftMargin: 10
            right: parent.right
            rightMargin: 10
          }
          clip: true
          spacing: 2
          model: ScriptModel {
            values: root.filteredApps
            objectProp: "id"
          }

          delegate: Rectangle {
            id: appRow
            required property var modelData
            required property int index
            width: appList.width
            height: 56
            radius: Theme.radius
            color: index === root.selectedIndex ? Qt.rgba(0.49, 0.61, 0.85, 0.12) : (rowHover.hovered ? Qt.rgba(0.49, 0.61, 0.85, 0.06) : "transparent")

            Rectangle {
              visible: appRow.index === root.selectedIndex
              anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: 7
                bottomMargin: 7
              }
              width: 3
              color: Theme.coral
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 13

              IconImage {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                implicitSize: 34
                source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                asynchronous: true
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                  Layout.fillWidth: true
                  text: appRow.modelData.name
                  color: Theme.text
                  font.family: Theme.font
                  font.pixelSize: 13
                  elide: Text.ElideRight
                }

                Text {
                  Layout.fillWidth: true
                  text: appRow.modelData.genericName || appRow.modelData.comment || "Application"
                  color: Theme.muted
                  font.family: Theme.font
                  font.pixelSize: 10
                  elide: Text.ElideRight
                }
              }

              Text {
                text: "Alt+" + (appRow.index + 1)
                color: Theme.blue
                font.family: Theme.font
                font.pixelSize: 10
              }
            }

            HoverHandler {
              id: rowHover
              onHoveredChanged: if (hovered) root.selectedIndex = appRow.index
            }
            TapHandler { onTapped: root.launch(appRow.index) }
          }

          Text {
            anchors.centerIn: parent
            visible: appList.count === 0
            text: "No matching applications"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
          }
        }
      }
    }
  }
}
