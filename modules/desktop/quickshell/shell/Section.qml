import QtQuick
import QtQuick.Layouts

// Small caps section heading with an optional glyph action on the right.
RowLayout {
  id: root

  property string title
  property string action: ""
  signal triggered()

  Layout.fillWidth: true
  Layout.topMargin: 4

  Label {
    Layout.fillWidth: true
    text: root.title.toUpperCase()
    size: 10
    font.letterSpacing: 1.2
    font.weight: Font.DemiBold
    color: Theme.faint
  }
  Glyph {
    visible: root.action !== ""
    glyph: root.action
    size: 14
    color: mouse.containsMouse ? Theme.text : Theme.faint
    MouseArea {
      id: mouse
      anchors.fill: parent
      anchors.margins: -6
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.triggered()
    }
  }
}
