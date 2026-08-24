import QtQuick
import QtQuick.Controls

Item {
  id: root

  property string icon: ""
  property string label: ""
  property bool danger: false
  signal clicked()

  implicitWidth: 30
  implicitHeight: 30

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: hover.hovered ? Qt.rgba(0.89, 0.41, 0.46, 0.14) : "transparent"
    border.width: Theme.borderWidth
    border.color: hover.hovered ? (root.danger ? Theme.coral : Theme.muted) : Theme.border
  }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.danger ? Theme.coral : Theme.text
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 14
  }

  HoverHandler { id: hover }
  TapHandler { onTapped: root.clicked() }

  ToolTip.visible: hover.hovered
  ToolTip.text: root.label
  ToolTip.delay: 500
}
