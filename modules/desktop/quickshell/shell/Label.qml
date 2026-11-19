import QtQuick

Text {
  property bool monospace: false
  property int size: Theme.fontSize

  color: Theme.text
  font.family: monospace ? Theme.mono : Theme.sans
  font.pixelSize: size
  elide: Text.ElideRight
  verticalAlignment: Text.AlignVCenter
}
