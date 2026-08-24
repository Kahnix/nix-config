import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Scope {
  id: root
  required property var shell

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  PwObjectTracker {
    objects: [ Pipewire.defaultAudioSink ]
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      implicitHeight: Theme.barHeight + Theme.outerGap * 2
      exclusionMode: ExclusionMode.Auto

      anchors {
        top: true
        left: true
        right: true
      }

      Rectangle {
        id: bar
        anchors {
          fill: parent
          topMargin: Theme.outerGap
          leftMargin: Theme.outerGap
          rightMargin: Theme.outerGap
          bottomMargin: Theme.outerGap
        }
        radius: Theme.radius
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          spacing: 8

          Item {
            Layout.preferredWidth: 30
            Layout.fillHeight: true

            Text {
              anchors.centerIn: parent
              text: ""
              color: Theme.blue
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 17
            }

            HoverHandler { id: logoHover }
            TapHandler { onTapped: root.shell.toggleLauncher() }
            ToolTip.visible: logoHover.hovered
            ToolTip.text: "Applications"
            ToolTip.delay: 500
          }

          Row {
            Layout.fillHeight: true
            spacing: 1

            Repeater {
              model: 9

              delegate: Item {
                id: workspaceButton
                required property int index
                readonly property int workspaceId: index + 1
                readonly property var workspace: {
                  const values = Hyprland.workspaces.values;
                  for (let i = 0; i < values.length; i++) {
                    if (values[i].id === workspaceId) return values[i];
                  }
                  return null;
                }
                readonly property bool focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId
                readonly property bool occupied: workspace && workspace.toplevels.values.length > 0

                width: 31
                height: Theme.barHeight

                Text {
                  anchors.centerIn: parent
                  text: workspaceButton.workspaceId
                  color: workspaceButton.focused ? Theme.coral : (workspaceButton.occupied ? Theme.text : Theme.muted)
                  font.family: Theme.font
                  font.pixelSize: 12
                }

                Rectangle {
                  anchors.bottom: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: workspaceButton.focused ? 18 : (workspaceButton.occupied ? 4 : 0)
                  height: 2
                  color: workspaceButton.focused ? Theme.coral : Theme.blue

                  Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }

                HoverHandler { id: workspaceHover }
                TapHandler {
                  onTapped: {
                    if (workspaceButton.workspace)
                      workspaceButton.workspace.activate();
                    else
                      Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(workspaceButton.workspaceId)]);
                  }
                }
              }
            }
          }

          Text {
            Layout.leftMargin: 8
            Layout.maximumWidth: 320
            Layout.fillWidth: true
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "desktop"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 11
            elide: Text.ElideRight
          }

          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
              anchors.centerIn: parent
              text: Qt.formatDateTime(clock.date, "ddd  dd MMM   HH:mm")
              color: Theme.text
              font.family: Theme.font
              font.pixelSize: 12
            }

            HoverHandler { id: clockHover }
            TapHandler { onTapped: root.shell.toggleControlCenter() }
            ToolTip.visible: clockHover.hovered
            ToolTip.text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            ToolTip.delay: 500
          }

          RowLayout {
            Layout.fillHeight: true
            spacing: 4

            property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

            Text {
              visible: parent.player !== null
              Layout.maximumWidth: 180
              text: parent.player ? (parent.player.isPlaying ? "  " : "  ") + (parent.player.trackTitle || parent.player.identity) : ""
              color: Theme.muted
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
              elide: Text.ElideRight

              HoverHandler { id: mediaHover }
              TapHandler { onTapped: if (parent.parent.player && parent.parent.player.canTogglePlaying) parent.parent.player.togglePlaying() }
            }

            Repeater {
              model: SystemTray.items

              delegate: Item {
                id: trayItem
                required property var modelData
                width: 25
                height: Theme.barHeight

                IconImage {
                  anchors.centerIn: parent
                  implicitSize: 16
                  source: trayItem.modelData.icon
                }

                MouseArea {
                  anchors.fill: parent
                  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                  onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                      trayItem.modelData.display(barWindow, mouse.x, mouse.y);
                    else if (mouse.button === Qt.MiddleButton)
                      trayItem.modelData.secondaryActivate();
                    else
                      trayItem.modelData.activate();
                  }
                }
              }
            }

            Text {
              text: Status.networkKind === "wifi" ? "" : (Status.networkKind === "wired" ? "󰈀" : "󰤭")
              color: Status.networkKind === "none" ? Theme.coral : Theme.green
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 15

              HoverHandler { id: networkHover }
              TapHandler { onTapped: root.shell.toggleControlCenter() }
              ToolTip.visible: networkHover.hovered
              ToolTip.text: Status.networkName || "Network"
              ToolTip.delay: 500
            }

            Text {
              readonly property var sink: Pipewire.defaultAudioSink
              readonly property var audio: sink ? sink.audio : null
              text: !audio || audio.muted ? "󰝟" : (audio.volume > 0.55 ? "󰕾" : "󰖀")
              color: !audio || audio.muted ? Theme.muted : Theme.green
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 16

              HoverHandler { id: volumeHover }
              TapHandler { onTapped: root.shell.toggleControlCenter() }
              ToolTip.visible: volumeHover.hovered
              ToolTip.text: audio ? Math.round(audio.volume * 100) + "%" : "Audio unavailable"
              ToolTip.delay: 500
            }

            Item {
              Layout.preferredWidth: 30
              Layout.fillHeight: true

              Text {
                anchors.centerIn: parent
                text: "󰐥"
                color: Theme.coral
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
              }

              HoverHandler { id: powerHover }
              TapHandler { onTapped: root.shell.toggleControlCenter() }
              ToolTip.visible: powerHover.hovered
              ToolTip.text: "Power and controls"
              ToolTip.delay: 500
            }
          }
        }
      }
    }
  }
}
