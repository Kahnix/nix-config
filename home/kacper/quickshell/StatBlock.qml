import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  property string label: ""
  property string value: ""
  property color accent: Theme.blue

  implicitHeight: 48
  radius: Theme.radius
  color: Theme.surface
  border.width: Theme.borderWidth
  border.color: Theme.border

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 7

    Rectangle {
      Layout.preferredWidth: 3
      Layout.preferredHeight: 22
      radius: 1
      color: root.accent
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Text {
        text: root.label
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 8
      }
      Text {
        text: root.value
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 10
        elide: Text.ElideRight
      }
    }
  }
}
