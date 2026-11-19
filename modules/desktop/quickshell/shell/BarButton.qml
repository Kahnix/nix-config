import QtQuick
import QtQuick.Layouts

// Hover-highlighted bar segment. Children go into a centred row.
Item {
  id: root

  default property alias content: row.data
  property bool active: false
  property int padding: 8
  readonly property bool hovered: mouse.containsMouse

  signal clicked(int button)
  signal scrolled(int delta)

  implicitWidth: row.implicitWidth + padding * 2
  implicitHeight: Theme.barHeight - 8

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSmall
    color: root.active ? Theme.alpha(Theme.accent, 0.18) : root.hovered ? Theme.hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim } }
  }

  // A layout (not a Row) so every child is vertically centred.
  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: event => root.clicked(event.button)
    onWheel: event => root.scrolled(event.angleDelta.y)
  }
}
