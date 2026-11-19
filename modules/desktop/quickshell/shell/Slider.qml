import QtQuick

// Flat slider, 0..1. Emits `moved` while dragging, clicking or scrolling.
Item {
  id: root

  property real value: 0
  property color fill: Theme.accent
  property bool dimmed: false
  signal moved(real value)

  implicitHeight: 22

  function set(x) {
    root.moved(Math.max(0, Math.min(1, x / width)));
  }

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 3
    color: Theme.alpha(Theme.text, 0.1)

    Rectangle {
      width: Math.max(height, parent.width * Math.min(1, root.value))
      height: parent.height
      radius: parent.radius
      color: root.dimmed ? Theme.faint : root.fill
      Behavior on color { ColorAnimation { duration: Theme.anim } }
    }
  }

  Rectangle {
    x: Math.min(1, root.value) * (root.width - width)
    anchors.verticalCenter: parent.verticalCenter
    width: 14
    height: 14
    radius: 7
    color: Theme.bright
    scale: mouse.pressed ? 1.15 : mouse.containsMouse ? 1.0 : 0.85
    Behavior on scale { NumberAnimation { duration: 120 } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: event => root.set(event.x)
    onPositionChanged: event => { if (pressed) root.set(event.x); }
    onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
  }
}
