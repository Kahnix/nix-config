import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland

Scope {
  id: root
  required property var shell

  property alias server: notificationServer

  NotificationServer {
    id: notificationServer
    actionsSupported: true
    bodyMarkupSupported: false
    imageSupported: true
    persistenceSupported: true

    onNotification: notification => {
      notification.tracked = true;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: toastWindow
      required property var modelData
      readonly property var monitor: Hyprland.monitorFor(modelData)

      screen: modelData
      visible: !root.shell.controlCenterOpen
        && notificationServer.trackedNotifications.values.length > 0
        && monitor === Hyprland.focusedMonitor
      color: "transparent"
      implicitWidth: Math.min(380, modelData.width - 24)
      implicitHeight: Math.min(toastList.contentHeight + Theme.outerGap * 2, modelData.height - Theme.barHeight - 40)
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay

      anchors {
        top: true
        right: true
      }

      ListView {
        id: toastList
        anchors {
          fill: parent
          topMargin: Theme.barHeight + Theme.outerGap * 3
          leftMargin: Theme.outerGap
          rightMargin: Theme.outerGap
          bottomMargin: Theme.outerGap
        }
        spacing: 8
        clip: true
        model: notificationServer.trackedNotifications

        delegate: NotificationCard {
          required property var modelData
          width: toastList.width
          notification: modelData
          compact: true
        }
      }
    }
  }
}
