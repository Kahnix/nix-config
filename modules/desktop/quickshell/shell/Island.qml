import QtQuick
import QtQuick.Layouts

// One floating bar segment. Children go into a row; a faint top highlight
// gives the glass a lit edge.
Rectangle {
  id: root

  default property alias content: row.data
  property int padding: 4
  property color tint: "transparent"

  implicitWidth: row.implicitWidth + padding * 2
  implicitHeight: Theme.barHeight
  radius: Theme.radius
  color: Theme.surface
  border.width: 1
  border.color: Theme.border

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: root.tint
  }

  Rectangle {
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - parent.radius * 2
    height: 1
    color: Theme.alpha(Theme.bright, 0.07)
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 2
  }
}
