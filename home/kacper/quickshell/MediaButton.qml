import QtQuick

Item {
  id: root

  property string icon: ""
  property bool accent: false
  signal clicked()

  implicitWidth: 28
  implicitHeight: 28
  opacity: enabled ? 1 : 0.35

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: root.accent ? Theme.coral : (hover.hovered ? Qt.rgba(0.49, 0.61, 0.85, 0.14) : "transparent")
    border.width: Theme.borderWidth
    border.color: root.accent ? Theme.coral : Theme.border
  }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.accent ? Theme.base : Theme.text
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
  }

  HoverHandler { id: hover }
  TapHandler { enabled: root.enabled; onTapped: root.clicked() }
}
