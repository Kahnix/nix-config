import QtQuick
import QtQuick.Controls

Item {
  id: root

  property string icon: ""
  property string label: ""
  property bool danger: false
  signal clicked()

  implicitWidth: 34
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: hover.hovered ? Qt.rgba(0.07, 0.07, 0.09, 0.94) : Qt.rgba(0.07, 0.07, 0.09, 0.72)
    border.width: 1
    border.color: hover.hovered ? (root.danger ? "#e46876" : "#727169") : "#363646"
  }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.danger ? "#e46876" : "#dcd7ba"
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 15
  }

  HoverHandler { id: hover }
  TapHandler { onTapped: root.clicked() }

  ToolTip.visible: hover.hovered
  ToolTip.text: root.label
  ToolTip.delay: 500
}
