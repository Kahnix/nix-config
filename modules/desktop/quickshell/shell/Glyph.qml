import QtQuick

Text {
  property alias glyph: root.text
  property int size: 16

  id: root
  color: Theme.text
  font.family: Theme.mono
  font.pixelSize: size
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter

  Behavior on color { ColorAnimation { duration: Theme.anim } }
}
