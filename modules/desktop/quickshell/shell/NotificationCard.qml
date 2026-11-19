import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification. As a toast (`popup`) it hides itself after a while unless
// hovered or critical; it stays in the control center's history either way.
Rectangle {
  id: root

  required property Notification notification
  property bool popup: false
  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  readonly property string iconSource: {
    const img = notification.image;
    if (img) return img;
    const icon = notification.appIcon;
    if (!icon) return "";
    if (icon.startsWith("/") || icon.includes("://")) return icon;
    return Quickshell.iconPath(icon, true);
  }

  implicitHeight: layout.implicitHeight + 24
  radius: Theme.radius
  color: popup ? Theme.surface : Theme.card
  border.width: 1
  border.color: critical ? Theme.alpha(Theme.danger, 0.6) : popup ? Theme.border : Theme.cardBorder

  Timer {
    running: root.popup && !root.critical && !mouse.containsMouse
    interval: 6000
    onTriggered: Notifs.hide(root.notification)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: event => event.button === Qt.MiddleButton
      ? root.notification.dismiss()
      : Notifs.activate(root.notification)
  }

  RowLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12

    Item {
      Layout.alignment: Qt.AlignTop
      implicitWidth: 36
      implicitHeight: 36

      ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: "transparent"
        visible: root.iconSource !== ""
        IconImage {
          anchors.fill: parent
          source: root.iconSource
        }
      }
      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        visible: root.iconSource === ""
        color: Theme.alpha(Theme.accent, 0.15)
        Glyph { anchors.centerIn: parent; glyph: Theme.iBell; color: Theme.accent }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Label {
          Layout.fillWidth: true
          text: root.notification.appName || "Notification"
          size: Theme.fontSmall
          color: Theme.muted
        }
        Label {
          text: Ui.ago(Notifs.arrived[root.notification.id] ?? Date.now())
          size: Theme.fontSmall
          color: Theme.faint
        }
        Glyph {
          glyph: Theme.iClose
          size: 13
          color: close.containsMouse ? Theme.danger : Theme.faint
          MouseArea {
            id: close
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.notification.dismiss()
          }
        }
      }

      Label {
        Layout.fillWidth: true
        text: root.notification.summary
        font.weight: Font.DemiBold
        color: Theme.bright
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }

      Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.notification.body
        textFormat: Text.StyledText
        color: Theme.text
        size: 12
        wrapMode: Text.Wrap
        maximumLineCount: root.popup ? 4 : 3
        onLinkActivated: link => Qt.openUrlExternally(link)
      }

      Flow {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6
        visible: actions.count > 0

        Repeater {
          id: actions
          model: root.notification.actions.filter(a => a.identifier !== "default")

          Rectangle {
            required property NotificationAction modelData
            implicitWidth: actionLabel.implicitWidth + 20
            implicitHeight: 26
            radius: 13
            color: actionMouse.containsMouse ? Theme.alpha(Theme.accent, 0.3) : Theme.alpha(Theme.accent, 0.15)

            Label {
              id: actionLabel
              anchors.centerIn: parent
              text: modelData.text
              size: 12
              color: Theme.accent
            }
            MouseArea {
              id: actionMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: modelData.invoke()
            }
          }
        }
      }
    }
  }
}
