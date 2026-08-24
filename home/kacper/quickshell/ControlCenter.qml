import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
  id: root
  required property var shell
  required property var notificationServer

  readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

  PwObjectTracker {
    objects: [ Pipewire.defaultAudioSink ]
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: controlWindow
      required property var modelData
      readonly property var monitor: Hyprland.monitorFor(modelData)

      screen: modelData
      visible: root.shell.controlCenterOpen && monitor === Hyprland.focusedMonitor
      color: "transparent"
      implicitWidth: Math.min(404, modelData.width - 24)
      implicitHeight: Math.min(732, modelData.height - Theme.barHeight - 18)
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

      anchors {
        top: true
        right: true
      }

      Rectangle {
        anchors {
          fill: parent
          topMargin: Theme.barHeight + Theme.outerGap * 2
          rightMargin: Theme.outerGap
          bottomMargin: Theme.outerGap
          leftMargin: Theme.outerGap
        }
        radius: Theme.radius
        color: Theme.surfaceRaised
        border.width: Theme.borderWidth
        border.color: Theme.border

        ScrollView {
          anchors.fill: parent
          anchors.margins: 14
          clip: true
          contentWidth: availableWidth
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          ColumnLayout {
            width: parent.width
            spacing: 12

            RowLayout {
              Layout.fillWidth: true

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: "CONTROL CENTER"
                  color: Theme.text
                  font.family: Theme.font
                  font.pixelSize: 13
                  font.bold: true
                }

                Text {
                  text: Status.networkName
                  color: Theme.muted
                  font.family: Theme.font
                  font.pixelSize: 9
                }
              }

              Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28

                Text {
                  anchors.centerIn: parent
                  text: "󰅖"
                  color: closeHover.hovered ? Theme.coral : Theme.muted
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: root.shell.controlCenterOpen = false }
              }
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 3
              columnSpacing: 7
              rowSpacing: 7

              QuickAction {
                Layout.fillWidth: true
                icon: Status.networkKind === "wifi" ? "" : "󰈀"
                title: "Network"
                detail: Status.networkKind === "none" ? "Offline" : "Connected"
                active: Status.networkKind !== "none"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
              }

              QuickAction {
                Layout.fillWidth: true
                icon: "󰂯"
                title: "Bluetooth"
                detail: "Devices"
                active: true
                onClicked: Quickshell.execDetached(["blueman-manager"])
              }

              QuickAction {
                Layout.fillWidth: true
                icon: "󰒓"
                title: "Appearance"
                detail: "GTK / cursor"
                onClicked: Quickshell.execDetached(["nwg-look"])
              }
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: mediaContent.implicitHeight + 24
              radius: Theme.radius
              color: Theme.surface
              border.width: Theme.borderWidth
              border.color: Theme.border

              RowLayout {
                id: mediaContent
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  margins: 12
                }
                spacing: 12

                Rectangle {
                  Layout.preferredWidth: 54
                  Layout.preferredHeight: 54
                  radius: Theme.radius
                  color: Qt.rgba(0.49, 0.61, 0.85, 0.12)
                  clip: true

                  Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: !albumArt.visible
                    text: "󰝚"
                    color: Theme.blue
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 3

                  Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackTitle || root.player.identity) : "Nothing playing"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackArtist || root.player.identity) : "MPRIS media controls"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                    elide: Text.ElideRight
                  }

                  RowLayout {
                    spacing: 13

                    MediaButton {
                      icon: "󰒮"
                      enabled: root.player && root.player.canGoPrevious
                      onClicked: root.player.previous()
                    }
                    MediaButton {
                      icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                      enabled: root.player && root.player.canTogglePlaying
                      accent: true
                      onClicked: root.player.togglePlaying()
                    }
                    MediaButton {
                      icon: "󰒭"
                      enabled: root.player && root.player.canGoNext
                      onClicked: root.player.next()
                    }
                  }
                }
              }
            }

            Rectangle {
              id: audioCard
              readonly property var sink: Pipewire.defaultAudioSink
              readonly property var audio: sink ? sink.audio : null

              Layout.fillWidth: true
              implicitHeight: 64
              radius: Theme.radius
              color: Theme.surface
              border.width: Theme.borderWidth
              border.color: Theme.border

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                  text: !audioCard.audio || audioCard.audio.muted ? "󰝟" : "󰕾"
                  color: !audioCard.audio || audioCard.audio.muted ? Theme.muted : Theme.green
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 17

                  TapHandler {
                    onTapped: if (audioCard.audio) audioCard.audio.muted = !audioCard.audio.muted
                  }
                }

                Slider {
                  id: volumeSlider
                  Layout.fillWidth: true
                  from: 0
                  to: 1
                  value: audioCard.audio ? audioCard.audio.volume : 0
                  onMoved: if (audioCard.audio) audioCard.audio.volume = value

                  background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: volumeSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: Theme.border

                    Rectangle {
                      width: volumeSlider.visualPosition * parent.width
                      height: parent.height
                      radius: parent.radius
                      color: Theme.green
                    }
                  }

                  handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 13
                    implicitHeight: 13
                    radius: 7
                    color: Theme.text
                    border.width: Theme.borderWidth
                    border.color: Theme.green
                  }
                }

                Text {
                  Layout.preferredWidth: 36
                  horizontalAlignment: Text.AlignRight
                  text: audioCard.audio ? Math.round(audioCard.audio.volume * 100) + "%" : "--"
                  color: Theme.text
                  font.family: Theme.font
                  font.pixelSize: 10
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 7

              StatBlock { Layout.fillWidth: true; label: "CPU"; value: Status.cpuUsage + "%"; accent: Theme.blue }
              StatBlock { Layout.fillWidth: true; label: "MEM"; value: Status.memoryUsage + "%"; accent: Theme.green }
              StatBlock { Layout.fillWidth: true; label: "GPU"; value: "GTX 1070"; accent: Theme.coral }
            }

            RowLayout {
              Layout.fillWidth: true

              Text {
                Layout.fillWidth: true
                text: "NOTIFICATIONS"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
                font.bold: true
              }

              Text {
                visible: root.notificationServer.trackedNotifications.values.length > 0
                text: "Clear"
                color: clearHover.hovered ? Theme.coral : Theme.muted
                font.family: Theme.font
                font.pixelSize: 9

                HoverHandler { id: clearHover }
                TapHandler {
                  onTapped: {
                    const values = root.notificationServer.trackedNotifications.values.slice();
                    for (let i = 0; i < values.length; i++) values[i].dismiss();
                  }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 7

              Repeater {
                model: root.notificationServer.trackedNotifications

                delegate: NotificationCard {
                  required property var modelData
                  Layout.fillWidth: true
                  notification: modelData
                }
              }

              Text {
                visible: root.notificationServer.trackedNotifications.values.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                text: "No unread notifications"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 42
              radius: Theme.radius
              color: Theme.surface
              border.width: Theme.borderWidth
              border.color: Theme.border

              RowLayout {
                anchors.centerIn: parent
                spacing: 20

                PowerButton { icon: "󰌾"; label: "Lock"; onClicked: Quickshell.execDetached(["hyprlock"]) }
                PowerButton { icon: "󰍃"; label: "Log out"; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                PowerButton { icon: "󰜉"; label: "Restart"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                PowerButton { icon: "󰐥"; label: "Shut down"; danger: true; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
              }
            }
          }
        }
      }
    }
  }
}
