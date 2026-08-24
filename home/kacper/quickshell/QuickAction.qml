import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string detail: ""
  property bool active: false
  signal clicked()

  implicitHeight: 70
  radius: Theme.radius
  color: active ? Qt.rgba(0.49, 0.61, 0.85, 0.14) : Theme.surface
  border.width: Theme.borderWidth
  border.color: active ? Theme.blue : (hover.hovered ? Theme.muted : Theme.border)

  ColumnLayout {
    anchors.centerIn: parent
    width: parent.width - 12
    spacing: 3

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: root.icon
      color: root.active ? Theme.blue : Theme.text
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 17
    }

    Text {
      Layout.fillWidth: true
      text: root.title
      color: Theme.text
      font.family: Theme.font
      font.pixelSize: 9
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }

    Text {
      Layout.fillWidth: true
      text: root.detail
      color: Theme.muted
      font.family: Theme.font
      font.pixelSize: 8
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }

  HoverHandler { id: hover }
  TapHandler { onTapped: root.clicked() }
}
