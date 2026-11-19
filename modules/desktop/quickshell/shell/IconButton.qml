import QtQuick

// Round glyph button for panels.
Rectangle {
  id: root

  property string glyph
  property int size: 32
  property color tint: Theme.text
  property bool active: false
  signal clicked()

  implicitWidth: size
  implicitHeight: size
  radius: size / 2
  color: active ? Theme.alpha(Theme.accent, 0.22) : mouse.containsMouse ? Theme.hover : "transparent"
  Behavior on color { ColorAnimation { duration: Theme.anim } }

  Glyph {
    anchors.centerIn: parent
    glyph: root.glyph
    size: Math.round(root.size * 0.5)
    color: root.active ? Theme.accent : root.tint
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
