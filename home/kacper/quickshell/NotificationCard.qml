import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
  id: root

  required property var notification
  property bool compact: false

  implicitHeight: content.implicitHeight + 24
  radius: Theme.radius
  color: Theme.surfaceRaised
  border.width: Theme.borderWidth
  border.color: notification.urgency === NotificationUrgency.Critical ? Theme.coral : Theme.border

  RowLayout {
    id: content
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: 12
    }
    spacing: 10

    Rectangle {
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      Layout.alignment: Qt.AlignTop
      radius: Theme.radius
      color: Qt.rgba(0.49, 0.61, 0.85, 0.12)
      border.width: Theme.borderWidth
      border.color: Theme.border

      IconImage {
        anchors.centerIn: parent
        implicitSize: 22
        source: root.notification.image || Quickshell.iconPath(root.notification.appIcon, "dialog-information")
        asynchronous: true
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          Layout.fillWidth: true
          text: root.notification.summary || root.notification.appName || "Notification"
          color: Theme.text
          font.family: Theme.font
          font.pixelSize: 12
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          text: root.notification.appName
          color: Theme.muted
          font.family: Theme.font
          font.pixelSize: 9
          elide: Text.ElideRight
          Layout.maximumWidth: 90
        }
      }

      Text {
        visible: text.length > 0
        Layout.fillWidth: true
        text: root.notification.body
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 10
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: root.compact ? 2 : 4
        elide: Text.ElideRight
      }

      RowLayout {
        visible: root.notification.actions.length > 0
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: root.notification.actions.slice(0, 2)

          delegate: Rectangle {
            id: actionButton
            required property var modelData
            Layout.preferredHeight: 25
            Layout.preferredWidth: Math.max(64, actionLabel.implicitWidth + 18)
            radius: Theme.radius
            color: actionHover.hovered ? Qt.rgba(0.49, 0.61, 0.85, 0.16) : Theme.surface
            border.width: Theme.borderWidth
            border.color: actionHover.hovered ? Theme.blue : Theme.border

            Text {
              id: actionLabel
              anchors.centerIn: parent
              text: actionButton.modelData.text
              color: Theme.text
              font.family: Theme.font
              font.pixelSize: 9
              elide: Text.ElideRight
            }

            HoverHandler { id: actionHover }
            TapHandler { onTapped: actionButton.modelData.invoke() }
          }
        }
      }
    }

    Item {
      Layout.preferredWidth: 22
      Layout.preferredHeight: 22
      Layout.alignment: Qt.AlignTop

      Text {
        anchors.centerIn: parent
        text: "󰅖"
        color: closeHover.hovered ? Theme.coral : Theme.muted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
      }

      HoverHandler { id: closeHover }
      TapHandler { onTapped: root.notification.dismiss() }
    }
  }
}
