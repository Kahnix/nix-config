import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Item {
  id: root

  property string iconName: ""
  property string label: ""
  property color iconColor: Theme.text
  property bool selected: false
  property int buttonSize: 30
  signal clicked()

  implicitWidth: buttonSize
  implicitHeight: buttonSize

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: root.selected || hover.hovered ? Qt.rgba(0.49, 0.61, 0.85, 0.14) : "transparent"
    border.width: Theme.borderWidth
    border.color: root.selected ? Theme.blue : (hover.hovered ? Theme.muted : Theme.border)
  }

  IconImage {
    anchors.centerIn: parent
    implicitSize: Math.round(root.buttonSize * 0.52)
    source: Quickshell.iconPath(root.iconName, "application-x-executable")
    asynchronous: true
  }

  HoverHandler { id: hover }
  TapHandler { onTapped: root.clicked() }

  ToolTip.visible: hover.hovered && root.label.length > 0
  ToolTip.text: root.label
  ToolTip.delay: 500
}
